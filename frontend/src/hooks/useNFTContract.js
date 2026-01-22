import { useState, useEffect, useCallback } from 'react'
import { ethers } from 'ethers'

// Full contract ABI for NFTminimint
const NFT_ABI = [
  // Read functions
  'function name() public view returns (string)',
  'function symbol() public view returns (string)',
  'function tokenURI(uint256 tokenId) public view returns (string)',
  'function balanceOf(address owner) public view returns (uint256)',
  'function ownerOf(uint256 tokenId) public view returns (address)',
  'function totalSupply() external view returns (uint256)',
  'function mintFee() public view returns (uint256)',
  'function maxSupply() public view returns (uint256)',
  'function maxPerWallet() public view returns (uint256)',
  'function mintedByWallet(address) public view returns (uint256)',
  'function paused() public view returns (bool)',
  'function owner() public view returns (address)',
  
  // Write functions
  'function mintNFT(address to, string memory tokenURI) external payable',
  
  // Events
  'event Transfer(address indexed from, address indexed to, uint256 indexed tokenId)',
  'event NFTMinted(address indexed to, uint256 indexed tokenId, string tokenURI)'
]

const CONTRACT_ADDRESS = import.meta.env.VITE_CONTRACT_ADDRESS || '0x5FbDB2315678afecb367f032d93F642f64180aa3'

export function useNFTContract(account) {
  const [contract, setContract] = useState(null)
  const [readContract, setReadContract] = useState(null)
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState(null)

  // Contract info state
  const [name, setName] = useState('')
  const [symbol, setSymbol] = useState('')
  const [totalSupply, setTotalSupply] = useState(0)
  const [maxSupply, setMaxSupply] = useState(0)
  const [mintFee, setMintFee] = useState('0')
  const [maxPerWallet, setMaxPerWallet] = useState(0)
  const [userMinted, setUserMinted] = useState(0)
  const [userBalance, setUserBalance] = useState(0)
  const [isPaused, setIsPaused] = useState(false)
  const [contractOwner, setContractOwner] = useState('')

  // Initialize contracts
  useEffect(() => {
    if (typeof window.ethereum === 'undefined') {
      setError('Please install MetaMask')
      return
    }

    try {
      const provider = new ethers.providers.Web3Provider(window.ethereum)
      
      // Read-only contract
      const readOnlyContract = new ethers.Contract(CONTRACT_ADDRESS, NFT_ABI, provider)
      setReadContract(readOnlyContract)

      // Signer contract (if connected)
      if (account) {
        const signer = provider.getSigner()
        const signerContract = new ethers.Contract(CONTRACT_ADDRESS, NFT_ABI, signer)
        setContract(signerContract)
      } else {
        setContract(null)
      }
    } catch (err) {
      console.error('Error initializing contracts:', err)
      setError('Failed to initialize contract')
    }
  }, [account])

  // Fetch static contract info (name, symbol, maxSupply, etc.)
  const fetchStaticInfo = useCallback(async () => {
    if (!readContract) return

    try {
      const [contractName, contractSymbol, maxSup, perWallet, owner] = await Promise.all([
        readContract.name(),
        readContract.symbol(),
        readContract.maxSupply(),
        readContract.maxPerWallet(),
        readContract.owner()
      ])

      setName(contractName)
      setSymbol(contractSymbol)
      setMaxSupply(maxSup.toNumber())
      setMaxPerWallet(perWallet.toNumber())
      setContractOwner(owner)
    } catch (err) {
      console.error('Error fetching static info:', err)
    }
  }, [readContract])

  // Fetch dynamic contract info (totalSupply, paused, mintFee)
  const fetchDynamicInfo = useCallback(async () => {
    if (!readContract) return

    try {
      const [supply, fee, paused] = await Promise.all([
        readContract.totalSupply(),
        readContract.mintFee(),
        readContract.paused()
      ])

      setTotalSupply(supply.toNumber())
      setMintFee(fee.toString())
      setIsPaused(paused)
    } catch (err) {
      console.error('Error fetching dynamic info:', err)
    }
  }, [readContract])

  // Fetch user-specific info
  const fetchUserInfo = useCallback(async () => {
    if (!readContract || !account) return

    try {
      const [minted, balance] = await Promise.all([
        readContract.mintedByWallet(account),
        readContract.balanceOf(account)
      ])

      setUserMinted(minted.toNumber())
      setUserBalance(balance.toNumber())
    } catch (err) {
      console.error('Error fetching user info:', err)
    }
  }, [readContract, account])

  // Fetch all info
  const fetchAll = useCallback(async () => {
    setIsLoading(true)
    await Promise.all([
      fetchStaticInfo(),
      fetchDynamicInfo(),
      fetchUserInfo()
    ])
    setIsLoading(false)
  }, [fetchStaticInfo, fetchDynamicInfo, fetchUserInfo])

  // Initial fetch and refresh on account change
  useEffect(() => {
    fetchAll()
  }, [fetchAll])

  // Mint function
  const mint = useCallback(async (tokenURI) => {
    if (!contract || !account) {
      throw new Error('Not connected')
    }

    setIsLoading(true)
    setError(null)

    try {
      const tx = await contract.mintNFT(account, tokenURI, {
        value: mintFee
      })

      const receipt = await tx.wait()
      
      // Parse the NFTMinted event
      const mintEvent = receipt.events?.find(e => e.event === 'NFTMinted')
      const tokenId = mintEvent?.args?.tokenId?.toNumber() || 0

      // Refresh data
      await Promise.all([fetchDynamicInfo(), fetchUserInfo()])

      return {
        txHash: receipt.transactionHash,
        tokenId,
        success: true
      }
    } catch (err) {
      console.error('Mint error:', err)
      const message = err.reason || err.message || 'Mint failed'
      setError(message)
      throw new Error(message)
    } finally {
      setIsLoading(false)
    }
  }, [contract, account, mintFee, fetchDynamicInfo, fetchUserInfo])

  // Get token URI
  const getTokenURI = useCallback(async (tokenId) => {
    if (!readContract) return null

    try {
      return await readContract.tokenURI(tokenId)
    } catch (err) {
      console.error('Error getting token URI:', err)
      return null
    }
  }, [readContract])

  // Get owner of token
  const getOwnerOf = useCallback(async (tokenId) => {
    if (!readContract) return null

    try {
      return await readContract.ownerOf(tokenId)
    } catch (err) {
      console.error('Error getting owner:', err)
      return null
    }
  }, [readContract])

  // Computed values
  const canMint = !isPaused && 
                  totalSupply < maxSupply && 
                  userMinted < maxPerWallet &&
                  !!account

  const mintFeeEth = ethers.utils.formatEther(mintFee)
  const progress = maxSupply > 0 ? (totalSupply / maxSupply) * 100 : 0
  const remainingSupply = maxSupply - totalSupply
  const remainingForUser = maxPerWallet - userMinted

  return {
    // Contract instances
    contract,
    contractAddress: CONTRACT_ADDRESS,
    
    // Contract info
    name,
    symbol,
    totalSupply,
    maxSupply,
    mintFee,
    mintFeeEth,
    maxPerWallet,
    isPaused,
    contractOwner,
    
    // User info
    userMinted,
    userBalance,
    
    // Computed values
    canMint,
    progress,
    remainingSupply,
    remainingForUser,
    
    // Actions
    mint,
    getTokenURI,
    getOwnerOf,
    refetch: fetchAll,
    
    // State
    isLoading,
    error
  }
}
