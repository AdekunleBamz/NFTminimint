import { useState, useEffect, useCallback } from 'react'
import { ethers } from 'ethers'

// Contract ABI - only the functions we need
const CONTRACT_ABI = [
  'function mintNFT(address to, string memory tokenURI) external payable',
  'function mintFee() public view returns (uint256)',
  'function maxSupply() public view returns (uint256)',
  'function maxPerWallet() public view returns (uint256)',
  'function totalSupply() external view returns (uint256)',
  'function mintedByWallet(address) public view returns (uint256)',
  'function paused() public view returns (bool)',
  'function name() public view returns (string)',
  'function symbol() public view returns (string)',
  'event NFTMinted(address indexed to, uint256 indexed tokenId, string tokenURI)'
]

// Default to localhost for development
const DEFAULT_CONTRACT_ADDRESS = import.meta.env.VITE_CONTRACT_ADDRESS || '0x5FbDB2315678afecb367f032d93F642f64180aa3'

export function useContract(account) {
  const [contract, setContract] = useState(null)
  const [contractInfo, setContractInfo] = useState({
    name: '',
    symbol: '',
    mintFee: null,
    maxSupply: null,
    totalSupply: null,
    maxPerWallet: null,
    mintedByUser: null,
    paused: false
  })
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState(null)
  const [txHash, setTxHash] = useState(null)

  // Initialize contract
  useEffect(() => {
    if (!account || typeof window.ethereum === 'undefined') {
      setContract(null)
      return
    }

    try {
      const provider = new ethers.providers.Web3Provider(window.ethereum)
      const signer = provider.getSigner()
      const nftContract = new ethers.Contract(DEFAULT_CONTRACT_ADDRESS, CONTRACT_ABI, signer)
      setContract(nftContract)
    } catch (err) {
      console.error('Error initializing contract:', err)
      setError('Failed to connect to contract')
    }
  }, [account])

  // Fetch contract info
  const fetchContractInfo = useCallback(async () => {
    if (!contract || !account) return

    try {
      const [name, symbol, mintFee, maxSupply, totalSupply, maxPerWallet, mintedByUser, paused] = await Promise.all([
        contract.name(),
        contract.symbol(),
        contract.mintFee(),
        contract.maxSupply(),
        contract.totalSupply(),
        contract.maxPerWallet(),
        contract.mintedByWallet(account),
        contract.paused().catch(() => false)
      ])

      setContractInfo({
        name,
        symbol,
        mintFee,
        maxSupply: maxSupply.toNumber(),
        totalSupply: totalSupply.toNumber(),
        maxPerWallet: maxPerWallet.toNumber(),
        mintedByUser: mintedByUser.toNumber(),
        paused
      })
    } catch (err) {
      console.error('Error fetching contract info:', err)
    }
  }, [contract, account])

  useEffect(() => {
    fetchContractInfo()
  }, [fetchContractInfo])

  // Mint function
  const mint = useCallback(async (tokenURI) => {
    if (!contract || !account) {
      setError('Please connect your wallet')
      return null
    }

    if (!tokenURI) {
      setError('Token URI is required')
      return null
    }

    setIsLoading(true)
    setError(null)
    setTxHash(null)

    try {
      const mintFee = await contract.mintFee()
      
      const tx = await contract.mintNFT(account, tokenURI, {
        value: mintFee
      })

      setTxHash(tx.hash)

      const receipt = await tx.wait()
      
      // Parse the NFTMinted event
      const mintEvent = receipt.events?.find(e => e.event === 'NFTMinted')
      const tokenId = mintEvent?.args?.tokenId?.toNumber()

      // Refresh contract info
      await fetchContractInfo()

      return {
        tokenId,
        tokenURI,
        txHash: tx.hash,
        to: account
      }
    } catch (err) {
      console.error('Minting error:', err)
      
      if (err.code === 4001) {
        setError('Transaction rejected by user')
      } else if (err.message?.includes('insufficient funds')) {
        setError('Insufficient funds for minting')
      } else if (err.message?.includes('SoldOut')) {
        setError('Collection is sold out')
      } else if (err.message?.includes('WalletLimitExceeded')) {
        setError('You have reached the wallet mint limit')
      } else if (err.message?.includes('Pausable: paused')) {
        setError('Minting is currently paused')
      } else {
        setError(err.reason || err.message || 'Minting failed')
      }
      
      return null
    } finally {
      setIsLoading(false)
    }
  }, [contract, account, fetchContractInfo])

  return {
    contract,
    contractInfo,
    mint,
    isLoading,
    error,
    txHash,
    contractAddress: DEFAULT_CONTRACT_ADDRESS,
    refetch: fetchContractInfo
  }
}
