const themeToggle = document.getElementById('themeToggle');
const root = document.documentElement;

const previewTitle = document.getElementById('previewTitle');
const previewSubtitle = document.getElementById('previewSubtitle');
const previewName = document.getElementById('previewName');
const previewDescription = document.getElementById('previewDescription');
const previewSupply = document.getElementById('previewSupply');
const previewUri = document.getElementById('previewUri');

const mintForm = document.getElementById('mintForm');

const setTheme = (theme) => {
  if (theme === 'dark') {
    root.setAttribute('data-theme', 'dark');
  } else {
    root.removeAttribute('data-theme');
  }
  localStorage.setItem('nftminimint-theme', theme);
};

const savedTheme = localStorage.getItem('nftminimint-theme');
if (savedTheme) {
  setTheme(savedTheme);
}

themeToggle?.addEventListener('click', () => {
  const isDark = root.getAttribute('data-theme') === 'dark';
  setTheme(isDark ? 'light' : 'dark');
});

mintForm?.addEventListener('input', (event) => {
  const formData = new FormData(mintForm);
  const name = formData.get('name') || 'Aurora';
  const symbol = formData.get('symbol') || 'AUR';
  const uri = formData.get('uri') || 'https://example.com/metadata.json';
  const description = formData.get('description') ||
    'Describe your drop to see it update in real time.';
  const supply = formData.get('supply') || '10';
  const fee = formData.get('fee') || '0.01';

  previewTitle.textContent = name;
  previewSubtitle.textContent = `${symbol} • ${fee} ETH`;
  previewName.textContent = name;
  previewDescription.textContent = description;
  previewSupply.textContent = supply;
  previewUri.textContent = uri;
});

mintForm?.addEventListener('submit', (event) => {
  event.preventDefault();
  const button = mintForm.querySelector('button[type="submit"]');
  if (!button) return;

  button.textContent = 'Minting...';
  button.disabled = true;

  setTimeout(() => {
    button.textContent = 'Preview & Mint';
    button.disabled = false;
    alert('Mint simulated! Connect your wallet to mint on-chain.');
  }, 1200);
});
