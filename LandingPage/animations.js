// ========== SCROLL REVEAL ==========
const revealObserver = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      entry.target.classList.add('visible');
      // Animate accent-line inside
      const line = entry.target.querySelector('.accent-line');
      if (line) line.classList.add('visible');
    }
  });
}, { threshold: 0.15 });

document.querySelectorAll('.reveal').forEach(el => revealObserver.observe(el));

// ========== PARTICLES ==========
function createParticles() {
  const hero = document.querySelector('.hero');
  if (!hero) return;
  const canvas = document.createElement('canvas');
  canvas.id = 'particles-canvas';
  canvas.style.cssText = `
    position:absolute;top:0;left:0;width:100%;height:100%;
    pointer-events:none;z-index:0;
  `;
  hero.prepend(canvas);

  const ctx = canvas.getContext('2d');
  let W, H, particles = [];

  function resize() {
    W = canvas.width  = hero.offsetWidth;
    H = canvas.height = hero.offsetHeight;
  }
  resize();
  window.addEventListener('resize', resize);

  class Particle {
    constructor() { this.reset(); }
    reset() {
      this.x  = Math.random() * W;
      this.y  = Math.random() * H;
      this.r  = Math.random() * 2 + 0.5;
      this.vx = (Math.random() - 0.5) * 0.4;
      this.vy = -Math.random() * 0.6 - 0.2;
      this.alpha = Math.random() * 0.5 + 0.2;
    }
    update() {
      this.x += this.vx;
      this.y += this.vy;
      this.alpha -= 0.002;
      if (this.y < -10 || this.alpha <= 0) this.reset();
    }
    draw() {
      ctx.save();
      ctx.globalAlpha = this.alpha;
      ctx.fillStyle = Math.random() > 0.7 ? '#10B981' : '#C9A227';
      ctx.beginPath();
      ctx.arc(this.x, this.y, this.r, 0, Math.PI * 2);
      ctx.fill();
      ctx.restore();
    }
  }

  for (let i = 0; i < 60; i++) particles.push(new Particle());

  function loop() {
    ctx.clearRect(0, 0, W, H);
    particles.forEach(p => { p.update(); p.draw(); });
    requestAnimationFrame(loop);
  }
  loop();
}
createParticles();

// ========== NAVBAR SCROLL EFFECT ==========
const navbar = document.querySelector('.navbar');
window.addEventListener('scroll', () => {
  if (window.scrollY > 60) {
    navbar.style.background = 'rgba(1, 8, 16, 0.98)';
    navbar.style.borderBottomColor = 'rgba(201,162,39,0.2)';
  } else {
    navbar.style.background = 'rgba(2, 12, 21, 0.96)';
    navbar.style.borderBottomColor = '#1E2D3A';
  }
});

// ========== SLIDING NAV INDICATOR ==========
const sections  = document.querySelectorAll('section[id]');
const navLinks  = document.querySelectorAll('.nav-links a');
const navList   = document.querySelector('.nav-links');

// Create the sliding indicator element
const indicator = document.createElement('div');
indicator.className = 'nav-indicator';
indicator.style.opacity = '0';
navList.appendChild(indicator);

function moveIndicatorTo(link) {
  if (!link) { indicator.style.opacity = '0'; return; }
  const listRect = navList.getBoundingClientRect();
  const linkRect = link.getBoundingClientRect();
  indicator.style.opacity = '1';
  indicator.style.left  = (linkRect.left - listRect.left) + 'px';
  indicator.style.width = linkRect.width + 'px';
}

function setActiveLink(link) {
  navLinks.forEach(a => a.classList.remove('active'));
  if (link) link.classList.add('active');
  moveIndicatorTo(link);
}

// Set initial active on hover (preview)
navLinks.forEach(a => {
  a.addEventListener('mouseenter', () => moveIndicatorTo(a));
  a.addEventListener('mouseleave', () => {
    const active = document.querySelector('.nav-links a.active');
    moveIndicatorTo(active || null);
  });
});

// Track active section on scroll
const activeObserver = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      const link = document.querySelector(`.nav-links a[href="#${entry.target.id}"]`);
      setActiveLink(link);
    }
  });
}, { rootMargin: '-30% 0px -60% 0px' });
sections.forEach(s => activeObserver.observe(s));

// Reposition on resize
window.addEventListener('resize', () => {
  const active = document.querySelector('.nav-links a.active');
  moveIndicatorTo(active || null);
});

// ========== COUNTER ANIMATION ==========
function animateCounter(el) {
  const target = parseInt(el.dataset.count, 10);
  const duration = 1500;
  const step = target / (duration / 16);
  let current = 0;
  const timer = setInterval(() => {
    current += step;
    if (current >= target) { current = target; clearInterval(timer); }
    el.textContent = Math.floor(current).toLocaleString() + (el.dataset.suffix || '');
  }, 16);
}
const counterObserver = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      animateCounter(entry.target);
      counterObserver.unobserve(entry.target);
    }
  });
}, { threshold: 0.5 });
document.querySelectorAll('[data-count]').forEach(el => counterObserver.observe(el));

// ========== SMOOTH SCROLL NAV ==========
document.querySelectorAll('a[href^="#"]').forEach(a => {
  a.addEventListener('click', e => {
    const target = document.querySelector(a.getAttribute('href'));
    if (!target) return;
    e.preventDefault();
    target.scrollIntoView({ behavior: 'smooth', block: 'start' });
  });
});

// ========== CURSOR GLOW (optional subtle effect) ==========
const glow = document.createElement('div');
glow.style.cssText = `
  position:fixed;pointer-events:none;z-index:9999;
  width:300px;height:300px;border-radius:50%;
  background:radial-gradient(circle,rgba(201,162,39,0.05) 0%,transparent 70%);
  transform:translate(-50%,-50%);transition:left 0.15s,top 0.15s;
`;
document.body.appendChild(glow);
document.addEventListener('mousemove', e => {
  glow.style.left = e.clientX + 'px';
  glow.style.top  = e.clientY + 'px';
});

// ========== TYPED TEXT EFFECT (hero title) ==========
const heroTitle = document.querySelector('.hero-title');
if (heroTitle) {
  heroTitle.style.opacity = '1';
}

// ========== CARD TILT EFFECT ==========
document.querySelectorAll('.program-card, .team-card').forEach(card => {
  card.addEventListener('mousemove', e => {
    const rect = card.getBoundingClientRect();
    const x = ((e.clientX - rect.left) / rect.width  - 0.5) * 12;
    const y = ((e.clientY - rect.top)  / rect.height - 0.5) * 12;
    card.style.transform = `translateY(-6px) rotateX(${-y}deg) rotateY(${x}deg)`;
    card.style.transition = 'transform 0.1s';
  });
  card.addEventListener('mouseleave', () => {
    card.style.transform = '';
    card.style.transition = 'transform 0.4s ease';
  });
});

// ========== STEP HIGHLIGHT ON SCROLL ==========
const stepObserver = new IntersectionObserver((entries) => {
  entries.forEach((entry, i) => {
    if (entry.isIntersecting) {
      entry.target.style.borderColor = 'rgba(201,162,39,0.5)';
      entry.target.style.background  = 'rgba(201,162,39,0.04)';
      setTimeout(() => {
        entry.target.style.borderColor = '';
        entry.target.style.background  = '';
        entry.target.style.transition  = 'all 1.5s ease';
      }, 1200);
    }
  });
}, { threshold: 0.8 });
document.querySelectorAll('.hiw-step').forEach(s => stepObserver.observe(s));
