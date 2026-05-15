<script lang="ts">
import { defineComponent, type PropType } from 'vue';
import type { Room } from '../data/rooms';
export default defineComponent({
  name: 'RoomCard',
  props: {
    room: {
      type: Object as PropType<Room>,
      required: true
    }
  },
  emits: ['toggle-favorite'],
  computed: {
    occupancyRate(): number {
      return (this.room.occupancy / this.room.capacity) * 100;
    },
    occupancyClass(): string {
      if (this.room.occupancy === 0) return 'is-free';
      if (this.occupancyRate < 80) return 'is-partial';
      return 'is-full';
    },
    statusLabel(): string {
      if (this.room.occupancy === 0) return '✅ Libre';
      if (this.occupancyRate < 80) return `🟡 ${this.room.occupancy}/${this.room.capacity}`;
      return `🔴 ${this.room.occupancy}/${this.room.capacity}`;
    }
  },
  methods: {
    onFavoriteClick() {
      this.$emit('toggle-favorite', this.room.id);
    }
  },
  watch: {
    'room.isFavorite'(newVal: boolean) {
      console.log(`[${this.room.name}] favori = ${newVal}`);
    }
  },
  mounted() {
    console.log(`RoomCard monté pour ${this.room.name}`);
  },beforeUnmount() {
    console.log(`RoomCard démonté pour ${this.room.name}`);
  }
});
</script>
<template>
  <article :class="['room-card', occupancyClass]">
    <header>
      <h3>{{ room.name }}</h3>
      <button class="fav-btn" @click="onFavoriteClick">
     {{ room.isFavorite ? '★' : '☆' }}
      </button>
    </header>
    <p>Bâtiment {{ room.building }} · {{ room.capacity }} places</p>
    <p class="status-badge">{{ statusLabel }}</p>
    <ul class="equipment-tags">
      <li v-for="eq in room.equipment" :key="eq">{{ eq }}</li>
    </ul>
  </article>
</template>
