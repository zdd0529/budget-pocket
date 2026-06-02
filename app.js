const STORAGE_KEY = "budget-pocket-data-v1";
const defaultData = {
  settings: {
    income: 0,
    creditCard: 0,
    carLoan: 0,
    rent: 0,
    parking: 0,
    creditDebt: 0,
    creditPaid: 0,
  },
  expenses: [],
};

const $ = (selector) => document.querySelector(selector);
const money = (value) =>
  new Intl.NumberFormat("zh-CN", { style: "currency", currency: "CNY" }).format(Number(value) || 0);
const today = () => new Date().toISOString().slice(0, 10);
const monthKey = (date = today()) => date.slice(0, 7);
const currentMonth = monthKey();
const categoryIcons = { "餐饮": "食", "交通": "行", "购物": "购", "生活": "家", "娱乐": "乐", "医疗": "医", "其他": "其" };

let data = loadData();

function loadData() {
  try {
    const saved = JSON.parse(localStorage.getItem(STORAGE_KEY));
    return {
      settings: { ...defaultData.settings, ...(saved?.settings || {}) },
      expenses: Array.isArray(saved?.expenses) ? saved.expenses : [],
    };
  } catch {
    return structuredClone(defaultData);
  }
}

function saveData() {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
}

function getFixedTotal() {
  const { creditCard, carLoan, rent, parking } = data.settings;
  return [creditCard, carLoan, rent, parking].reduce((sum, value) => sum + Number(value || 0), 0);
}

function getMonthExpenses() {
  return data.expenses
    .filter((expense) => monthKey(expense.date) === currentMonth)
    .sort((a, b) => b.date.localeCompare(a.date) || b.createdAt.localeCompare(a.createdAt));
}

function render() {
  const expenses = getMonthExpenses();
  const dailyTotal = expenses.reduce((sum, expense) => sum + Number(expense.amount), 0);
  const fixedTotal = getFixedTotal();
  const remaining = Number(data.settings.income) - fixedTotal - dailyTotal;
  const debt = Number(data.settings.creditDebt || 0);
  const paid = Math.min(Number(data.settings.creditPaid || 0), debt || Infinity);
  const debtRemaining = Math.max(debt - paid, 0);
  const progress = debt > 0 ? Math.min((paid / debt) * 100, 100) : 0;

  $("#currentMonthLabel").textContent = `${Number(currentMonth.slice(5))} 月可用`;
  $("#remainingAmount").textContent = money(remaining);
  $("#incomeAmount").textContent = money(data.settings.income);
  $("#fixedTotal").textContent = money(fixedTotal);
  $("#dailyTotal").textContent = money(dailyTotal);
  $("#creditPaid").textContent = money(paid);
  $("#creditRemaining").textContent = money(debtRemaining);
  $("#creditProgressText").textContent = `${Math.round(progress)}%`;
  $("#creditProgressBar").style.width = `${progress}%`;

  const status = $("#budgetStatus");
  status.textContent = remaining < 0 ? "已超出预算" : remaining < Number(data.settings.income) * 0.2 ? "注意节奏" : "预算充足";
  status.style.background = remaining < 0 ? "rgba(255, 178, 158, .22)" : "rgba(255,255,255,.14)";

  $("#recordCount").textContent = `${expenses.length} 笔`;
  $("#emptyState").hidden = expenses.length > 0;
  $("#recordList").innerHTML = expenses.map((expense) => `
    <article class="record">
      <span class="record-icon">${categoryIcons[expense.category] || "其"}</span>
      <div class="record-main">
        <strong>${escapeHtml(expense.note || expense.category)}</strong>
        <span>${expense.date} · ${escapeHtml(expense.category)}</span>
      </div>
      <strong class="record-amount">-${money(expense.amount)}</strong>
      <button class="delete-button" type="button" data-delete="${expense.id}" aria-label="删除这笔支出">×</button>
    </article>
  `).join("");
}

function escapeHtml(value) {
  const div = document.createElement("div");
  div.textContent = value;
  return div.innerHTML;
}

function showToast(message) {
  const toast = $("#toast");
  toast.textContent = message;
  toast.classList.add("show");
  clearTimeout(showToast.timeout);
  showToast.timeout = setTimeout(() => toast.classList.remove("show"), 1600);
}

function openSettings() {
  const form = $("#settingsForm");
  Object.entries(data.settings).forEach(([key, value]) => {
    if (form.elements[key]) form.elements[key].value = value || "";
  });
  $("#sheetBackdrop").hidden = false;
  $("#settingsSheet").classList.add("open");
  $("#settingsSheet").setAttribute("aria-hidden", "false");
  document.body.classList.add("sheet-open");
}

function closeSettings() {
  $("#settingsSheet").classList.remove("open");
  $("#settingsSheet").setAttribute("aria-hidden", "true");
  document.body.classList.remove("sheet-open");
  setTimeout(() => { $("#sheetBackdrop").hidden = true; }, 250);
}

$("#expenseDate").value = today();
$("#expenseForm").addEventListener("submit", (event) => {
  event.preventDefault();
  const form = new FormData(event.currentTarget);
  data.expenses.push({
    id: crypto.randomUUID ? crypto.randomUUID() : String(Date.now()),
    amount: Number(form.get("amount")),
    category: form.get("category"),
    date: form.get("date"),
    note: form.get("note").trim(),
    createdAt: new Date().toISOString(),
  });
  saveData();
  event.currentTarget.reset();
  $("#expenseDate").value = today();
  render();
  showToast("已记入账本");
});

$("#recordList").addEventListener("click", (event) => {
  const id = event.target.dataset.delete;
  if (!id) return;
  data.expenses = data.expenses.filter((expense) => expense.id !== id);
  saveData();
  render();
  showToast("已删除");
});

$("#settingsForm").addEventListener("submit", (event) => {
  event.preventDefault();
  const form = new FormData(event.currentTarget);
  Object.keys(data.settings).forEach((key) => {
    data.settings[key] = Math.max(0, Number(form.get(key) || 0));
  });
  saveData();
  render();
  closeSettings();
  showToast("计划已保存");
});

$("#settingsButton").addEventListener("click", openSettings);
$("#closeSettings").addEventListener("click", closeSettings);
$("#sheetBackdrop").addEventListener("click", closeSettings);

if ("serviceWorker" in navigator) {
  window.addEventListener("load", () => navigator.serviceWorker.register("./sw.js"));
}

render();
