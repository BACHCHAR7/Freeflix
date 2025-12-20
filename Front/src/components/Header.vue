<script setup>
import { ref, onMounted, onUnmounted } from 'vue';

const props = defineProps({
    categories: { type: Array, default: () => [] },
    activeFilter: { type: String, default: null }
});

const emit = defineEmits(['filter']);

const scrolled = ref(false);

function handleScroll() {
    scrolled.value = window.scrollY > 50;
}

function setFilter(filter) {
    emit('filter', filter);
}

onMounted(() => window.addEventListener('scroll', handleScroll));
onUnmounted(() => window.removeEventListener('scroll', handleScroll));
</script>

<template>
    <header :class="{ scrolled }">
        <div class="logo">
            <span class="logo-text">FREE<span class="accent">FLIX</span></span>
        </div>
        <nav>
            <a 
                href="#" 
                :class="{ active: !activeFilter }"
                @click.prevent="setFilter(null)"
            >Home</a>
            <a 
                v-for="cat in categories" 
                :key="cat.name"
                href="#" 
                :class="{ active: activeFilter === cat.name }"
                @click.prevent="setFilter(cat.name)"
            >{{ cat.name }}</a>
        </nav>
    </header>
</template>

<style scoped>
header {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    z-index: 100;
    display: flex;
    align-items: center;
    gap: 40px;
    padding: 20px 60px;
    background: linear-gradient(to bottom, rgba(0,0,0,0.8) 0%, transparent 100%);
    transition: background 0.3s ease;
}

header.scrolled {
    background: var(--bg-primary);
}

.logo-text {
    font-size: 1.8rem;
    font-weight: 700;
    letter-spacing: -1px;
}

.logo-text .accent {
    color: var(--accent);
}

nav {
    display: flex;
    gap: 24px;
}

nav a {
    color: var(--text-secondary);
    font-size: 0.95rem;
    font-weight: 500;
    transition: color var(--transition);
}

nav a:hover,
nav a.active {
    color: var(--text-primary);
}
</style>
