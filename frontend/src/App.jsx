import { useState } from 'react'
import { useWallet } from './hooks/useWallet'
import { useContract } from './hooks/useContract'
import Header from './components/Header'
import MintCard from './components/MintCard'
import Stats from './components/Stats'
import RecentMints from './components/RecentMints'
import Footer from './components/Footer'
import './App.css'

function App() {
  const { account, chainId, connect, disconnect, isConnecting, provider, error: walletError } = useWallet()
  const { contractInfo, mint, isLoading, error: contractError, contractAddress } = useContract(account)
  
  const [recentMints, setRecentMints] = useState([])

  const handleMint = async (tokenURI) => {
    const result = await mint(tokenURI)
    if (result) {
      setRecentMints(prev => [result, ...prev].slice(0, 5))
    }
    return result
  }

  const isConnected = !!account

  return (
    <div className="app">
      <Header 
        account={account}
        chainId={chainId}
        onConnect={connect}
        onDisconnect={disconnect}
        isConnecting={isConnecting}
      />
      
      <main className="main">
        <section className="hero">
          <div className="hero__content">
            <span className="hero__badge">ERC-721</span>
            <h1 className="hero__title">NFTminimint</h1>
            <p className="hero__subtitle">
              A minimal, gas-efficient NFT minting experience on Ethereum
            </p>
          </div>
        </section>

        {(walletError || contractError) && (
          <div className="error-banner">
            <span className="error-banner__icon">⚠️</span>
            <span>{walletError || contractError}</span>
          </div>
        )}

        <div className="content-grid">
          <div className="content-grid__main">
            <MintCard 
              contractInfo={contractInfo}
              onMint={handleMint}
              account={account}
              isConnected={isConnected}
              onConnect={connect}
            />
          </div>
          
          <aside className="content-grid__sidebar">
            <Stats contractInfo={contractInfo} isLoading={isLoading} />
            <RecentMints provider={provider} contractAddress={contractAddress} />
          </aside>
        </div>
      </main>

      <Footer />
    </div>
  )
}

export default App
