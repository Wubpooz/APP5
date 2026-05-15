<script setup lang="ts">
  import { ref } from 'vue';
  const campusName = ref('Polytech Paris-Sud');
  const today = new Date().toLocaleDateString('fr-FR', {
    weekday: 'long', year: 'numeric', month: 'long', day: 'numeric'
  });
  const counter = ref(0);
</script>

<template>
  <header class="campus-navbar">
    <span class="brand">🏫 Smart Campus Dashboard</span>
  </header>
  <main class="page">
    <div class="page-header">
      <h1>Bienvenue sur le campus de {{ campusName }}</h1>
      <p class="subtitle">{{ today }}</p>
    </div>
    <div class="detail-box" style="text-align: center;">
      <h2>Démo réactivité</h2>
      <p style="font-size: 4rem; font-weight: 700; color: var(--vue-green);">{{ counter }}</p>
      <div style="display: flex; gap: 8px; justify-content: center;">
        <button class="btn" @click="counter--">- 1</button>
        <button class="btn" @click="counter = 0">Reset</button>
        <button class="btn btn-primary" @click="counter++">+ 1</button>
      </div>
    </div>
  </main>
</template>