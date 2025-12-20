<script setup>
import { computed } from 'vue';

const props = defineProps({
    video: Object
});

const emit = defineEmits(['play', 'info']);

const thumbnailUrl = computed(() => `/api/thumbnail/${props.video.path}`);
</script>

<template>
    <section class="hero">
        <div class="backdrop">
            <img :src="thumbnailUrl" :alt="video.name" />
            <div class="gradient"></div>
        </div>
        
        <div class="info">
            <span class="badge">{{ video.category }} - {{ video.genre }}</span>
            <h1>{{ video.name }}</h1>
            <div class="actions">
                <button class="play" @click="emit('play')">
                    <svg viewBox="0 0 24 24" fill="currentColor">
                        <path d="M8 5v14l11-7z"/>
                    </svg>
                    Play
                </button>
                <button class="more" @click="emit('info')">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <circle cx="12" cy="12" r="10"/>
                        <path d="M12 16v-4m0-4h.01"/>
                    </svg>
                    More Info
                </button>
            </div>
        </div>
    </section>
</template>

<style scoped>
.hero {
    position: relative;
    height: 85vh;
    min-height: 600px;
}

.backdrop {
    position: absolute;
    inset: 0;
}

.backdrop img {
    width: 100%;
    height: 100%;
    object-fit: cover;
}

.gradient {
    position: absolute;
    inset: 0;
    background: 
        linear-gradient(to right, rgba(10,10,10,0.9) 0%, rgba(10,10,10,0.4) 50%, transparent 100%),
        linear-gradient(to top, var(--bg-primary) 0%, transparent 50%);
}

.info {
    position: absolute;
    bottom: 25%;
    left: 60px;
    max-width: 500px;
    z-index: 10;
}

.badge {
    display: inline-block;
    padding: 6px 12px;
    background: var(--accent);
    color: white;
    font-size: 0.75rem;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    border-radius: 2px;
    margin-bottom: 16px;
}

h1 {
    font-size: 3rem;
    font-weight: 700;
    line-height: 1.1;
    margin-bottom: 24px;
    text-shadow: 0 2px 10px rgba(0,0,0,0.5);
}

.actions {
    display: flex;
    gap: 12px;
}

button {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 14px 28px;
    font-size: 1.1rem;
    font-weight: 600;
    border-radius: 4px;
    transition: all var(--transition);
}

button svg {
    width: 24px;
    height: 24px;
}

.play {
    background: white;
    color: var(--bg-primary);
}

.play:hover {
    background: rgba(255,255,255,0.85);
}

.more {
    background: rgba(255,255,255,0.2);
    color: white;
}

.more:hover {
    background: rgba(255,255,255,0.3);
}
</style>
