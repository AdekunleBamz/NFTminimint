import { ethers } from 'ethers'
import './Header.css'

function Header({ account, chainId, onConnect, onDisconnect, isConnecting }) {
  const formatAddress = (addr) => {
    if (!addr) return ''
    return `${addr.slice(0, 6)}...${addr.slice(-4)}`
  }

  const getChainName = (id) => {
    const chains = {
      1: 'Ethereum',
      5: 'Goerli',
      11155111: 'Sepolia',
      31337: 'Localhost',
      137: 'Polygon',
      80001: 'Mumbai'
    }
    return chains[id] || `Chain ${id}`
  }

  return (
    <header className="header">
      <div className="header__brand">
        <span className="header__logo">◆</span>
        <span className="header__title">NFTminimint</span>
      </div>

      <div className="header__wallet">
        {account ? (
          <>
            <span className="header__chain">{getChainName(chainId)}</span>
            <span className="header__address">{formatAddress(account)}</span>
            <button 
              className="header__btn header__btn--disconnect"
              onClick={onDisconnect}
            >
              Disconnect
            </button>
          </>
        ) : (
          <button 
            className="header__btn header__btn--connect"
            onClick={onConnect}
            disabled={isConnecting}
          >
            {isConnecting ? 'Connecting...' : 'Connect Wallet'}
          </button>
        )}
      </div>
    </header>
  )
}

export default Header
