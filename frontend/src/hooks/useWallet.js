import { useState, useEffect, useCallback } from 'react'
import { ethers } from 'ethers'

const SUPPORTED_CHAINS = {
  1: 'Ethereum Mainnet',
  5: 'Goerli Testnet',
  11155111: 'Sepolia Testnet',
  31337: 'Localhost',
  137: 'Polygon Mainnet',
  80001: 'Polygon Mumbai'
}

export function useWallet() {
  const [account, setAccount] = useState(null)
  const [chainId, setChainId] = useState(null)
  const [isConnecting, setIsConnecting] = useState(false)
  const [error, setError] = useState(null)

  const getProvider = useCallback(() => {
    if (typeof window.ethereum !== 'undefined') {
      return new ethers.providers.Web3Provider(window.ethereum)
    }
    return null
  }, [])

  const connect = useCallback(async () => {
    setError(null)
    setIsConnecting(true)

    try {
      if (typeof window.ethereum === 'undefined') {
        throw new Error('Please install MetaMask or another Web3 wallet')
      }

      const provider = getProvider()
      const accounts = await provider.send('eth_requestAccounts', [])
      
      if (accounts.length === 0) {
        throw new Error('No accounts found')
      }

      const network = await provider.getNetwork()
      
      setAccount(accounts[0])
      setChainId(network.chainId)
    } catch (err) {
      console.error('Wallet connection error:', err)
      setError(err.message || 'Failed to connect wallet')
    } finally {
      setIsConnecting(false)
    }
  }, [getProvider])

  const disconnect = useCallback(() => {
    setAccount(null)
    setChainId(null)
    setError(null)
  }, [])

  useEffect(() => {
    if (typeof window.ethereum === 'undefined') return

    const handleAccountsChanged = (accounts) => {
      if (accounts.length === 0) {
        disconnect()
      } else {
        setAccount(accounts[0])
      }
    }

    const handleChainChanged = (chainIdHex) => {
      const newChainId = parseInt(chainIdHex, 16)
      setChainId(newChainId)
    }

    window.ethereum.on('accountsChanged', handleAccountsChanged)
    window.ethereum.on('chainChanged', handleChainChanged)

    // Check if already connected
    const checkConnection = async () => {
      try {
        const provider = getProvider()
        const accounts = await provider.listAccounts()
        if (accounts.length > 0) {
          const network = await provider.getNetwork()
          setAccount(accounts[0])
          setChainId(network.chainId)
        }
      } catch (err) {
        console.error('Error checking connection:', err)
      }
    }

    checkConnection()

    return () => {
      if (window.ethereum.removeListener) {
        window.ethereum.removeListener('accountsChanged', handleAccountsChanged)
        window.ethereum.removeListener('chainChanged', handleChainChanged)
      }
    }
  }, [disconnect, getProvider])

  const chainName = chainId ? (SUPPORTED_CHAINS[chainId] || `Chain ${chainId}`) : null
  const isSupported = chainId ? chainId in SUPPORTED_CHAINS : false
  const provider = getProvider()

  return {
    account,
    chainId,
    chainName,
    isSupported,
    connect,
    disconnect,
    isConnecting,
    error,
    provider
  }
}
