const projects = window.portfolioProjects;

const gate = document.querySelector("#access-gate");
const gateForm = document.querySelector("#gate-form");
const gatePassword = document.querySelector("#gate-password");
const gateError = document.querySelector("#gate-error");
const accessKey = "daye-portfolio-access";
const accessPassword = "321321";

function unlockPortfolio() {
  sessionStorage.setItem(accessKey, "granted");
  document.body.classList.remove("gate-locked");
  gate.classList.add("unlocked");
}

if (sessionStorage.getItem(accessKey) === "granted") {
  gate.classList.add("unlocked");
} else {
  document.body.classList.add("gate-locked");
  window.setTimeout(() => gatePassword.focus(), 150);
}

gateForm.addEventListener("submit", event => {
  event.preventDefault();
  if (gatePassword.value === accessPassword) {
    gateError.textContent = "";
    unlockPortfolio();
  } else {
    gateError.textContent = "密码不正确，请重新输入";
    gatePassword.value = "";
    gatePassword.focus();
  }
});

const list = document.querySelector("#project-list");
const modal = document.querySelector("#project-modal");
const gallery = document.querySelector("#modal-gallery");
let activeIndex = 0;

function projectImage(project, file) {
  if (file.includes("/")) return file;
  return `web-images/${project.folder}/${file}`;
}

function projectNumber(index) {
  return String(index + 1).padStart(2, "0");
}

function renderProjects() {
  document.querySelector(".section-heading span").textContent = `01 — ${projectNumber(projects.length - 1)}`;
  list.innerHTML = projects.map((project, index) => `
    <article class="project reveal" data-index="${index}" tabindex="0" role="button" aria-label="查看 ${project.title} 项目">
      <span class="project-number">${projectNumber(index)}</span>
      <div class="project-image">
        <img src="${project.cover}" alt="${project.title} 项目封面" loading="lazy" />
      </div>
      <div class="project-title">
        <h3>${project.title}</h3>
        <p>${project.category}</p>
      </div>
      <span class="project-arrow">→</span>
    </article>
  `).join("");

  list.querySelectorAll(".project").forEach(card => {
    const open = () => openProject(Number(card.dataset.index));
    card.addEventListener("click", open);
    card.addEventListener("keydown", event => {
      if (event.key === "Enter" || event.key === " ") open();
    });
  });
}

function openProject(index) {
  const project = projects[index];
  activeIndex = index;
  document.querySelector("#modal-count").textContent = `${projectNumber(index)} / ${projectNumber(projects.length - 1)}`;
  document.querySelector("#modal-meta").textContent = `PROJECT ${projectNumber(index)} · ${project.year}`;
  document.querySelector("#modal-title").textContent = project.title;
  document.querySelector("#modal-category").textContent = project.category;
  document.querySelector("#modal-desc").textContent = project.desc;

  gallery.innerHTML = project.files.map((file, imageIndex) => {
    const wide = imageIndex === 0 || imageIndex % 5 === 0 ? " wide" : "";
    return `<figure class="gallery-item${wide}">
      <img src="${projectImage(project, file)}" alt="${project.title} 项目展示图 ${imageIndex + 1}" loading="lazy" />
    </figure>`;
  }).join("");

  modal.classList.add("active");
  modal.setAttribute("aria-hidden", "false");
  document.body.classList.add("modal-open");
  modal.scrollTop = 0;
}

function closeProject() {
  modal.classList.remove("active");
  modal.setAttribute("aria-hidden", "true");
  document.body.classList.remove("modal-open");
}

document.querySelectorAll(".modal-close").forEach(button => button.addEventListener("click", closeProject));
document.querySelector(".next-project").addEventListener("click", () => openProject((activeIndex + 1) % projects.length));
document.addEventListener("keydown", event => {
  if (event.key === "Escape") closeProject();
});

const menuButton = document.querySelector(".menu-button");
const nav = document.querySelector(".site-nav");
menuButton.addEventListener("click", () => {
  nav.classList.toggle("open");
  menuButton.setAttribute("aria-expanded", nav.classList.contains("open"));
});
nav.querySelectorAll("a").forEach(link => link.addEventListener("click", () => nav.classList.remove("open")));

const observer = new IntersectionObserver(entries => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      entry.target.classList.add("visible");
      observer.unobserve(entry.target);
    }
  });
}, { threshold: 0.12 });

renderProjects();
document.querySelectorAll(".reveal").forEach(element => observer.observe(element));
