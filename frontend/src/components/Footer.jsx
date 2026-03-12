import './Footer.css'

function Footer() {
  const currentYear = new Date().getFullYear()

  const links = {
    project: [
      { label: 'Ethereum', href: 'https://ethereum.org/' },
      { label: 'Etherscan', href: 'https://etherscan.io/' },
      { label: 'IPFS Docs', href: 'https://docs.ipfs.tech/' }
    ],
    community: [
      { label: 'OpenSea', href: 'https://opensea.io/' },
      { label: 'X', href: 'https://x.com/ethereum' },
      { label: 'MetaMask', href: 'https://metamask.io/' }
    ],
    resources: [
      { label: 'ERC-721 Docs', href: 'https://eips.ethereum.org/EIPS/eip-721' },
      { label: 'GitHub', href: 'https://github.com/AdekunleBamz/NFTminimint' },
      { label: 'OpenZeppelin', href: 'https://docs.openzeppelin.com/contracts/' }
    ]
  }

  return (
    <footer className="footer">
      <div className="footer__content">
        <div className="footer__brand">
          <span className="footer__logo">◆</span>
          <span className="footer__title">NFTminimint</span>
          <p className="footer__description">
            Mint ERC-721 collectibles with a cleaner wallet flow,
            clearer status feedback, and a gallery built for quick browsing.
          </p>
        </div>

        <div className="footer__links">
          <div className="footer__column">
            <h4 className="footer__heading">Project</h4>
            <ul className="footer__list">
              {links.project.map((link, i) => (
                <li key={i}>
                  <a href={link.href} className="footer__link" target="_blank" rel="noopener noreferrer">{link.label}</a>
                </li>
              ))}
            </ul>
          </div>

          <div className="footer__column">
            <h4 className="footer__heading">Community</h4>
            <ul className="footer__list">
              {links.community.map((link, i) => (
                <li key={i}>
                  <a href={link.href} className="footer__link">{link.label}</a>
                </li>
              ))}
            </ul>
          </div>

          <div className="footer__column">
            <h4 className="footer__heading">Resources</h4>
            <ul className="footer__list">
              {links.resources.map((link, i) => (
                <li key={i}>
                  <a 
                    href={link.href} 
                    className="footer__link"
                    target={link.href.startsWith('http') ? '_blank' : undefined}
                    rel={link.href.startsWith('http') ? 'noopener noreferrer' : undefined}
                  >
                    {link.label}
                  </a>
                </li>
              ))}
            </ul>
          </div>
        </div>
      </div>

      <div className="footer__bottom">
        <p className="footer__copyright">
          © {currentYear} NFTminimint. All rights reserved.
        </p>
        <p className="footer__disclaimer">
          Built for Ethereum NFT drops
        </p>
      </div>
    </footer>
  )
}

export default Footer
