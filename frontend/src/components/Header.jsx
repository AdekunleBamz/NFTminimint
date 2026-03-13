import { useState } from 'react'
import './Header.css'

function Header({ account, chainId, onConnect, onDisconnect, isConnecting }) {
  const [copyStatus, setCopyStatus] = useState(null)

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

  const handleCopy = async () => {
    if (!account) return
    try {
      await navigator.clipboard.writeText(account)
      setCopyStatus('copied')
    } catch {
      setCopyStatus('failed')
    }
    window.setTimeout(() => setCopyStatus(null), 2000)
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
            <button
              type="button"
              className="header__address"
              onClick={handleCopy}
              aria-label={`Copy wallet address ${account}`}
              title="Copy wallet address"
            >
              <span className="header__address-label">Wallet</span>
              <span className="header__address-value" aria-hidden="true">{formatAddress(account)}</span>
              <span className="header__address-copy" aria-hidden="true">Copy</span>
              {copyStatus && (
                <span
                  className={`header__copied-toast ${
                    copyStatus === 'failed' ? 'header__copied-toast--error' : ''
                  }`}
                >
                  {copyStatus === 'copied' ? 'Copied' : 'Copy failed'}
                </span>
              )}
            </button>
            <button
              type="button"
              className="header__btn header__btn--disconnect"
              onClick={onDisconnect}
            >
              Disconnect
            </button>
          </>
        ) : (
          <button 
            type="button"
            className="header__btn header__btn--connect"
            onClick={onConnect}
            disabled={isConnecting}
          >
            {isConnecting ? 'Connecting...' : 'Connect Wallet'}
          </button>
        )}
      </div>
      <span className="sr-only" aria-live="polite">
        {copyStatus === 'copied' ? 'Wallet address copied.' : copyStatus === 'failed' ? 'Unable to copy wallet address.' : ''}
      </span>
    </header>
  )
}

export default Header
