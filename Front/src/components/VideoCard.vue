<script setup>
import { computed } from 'vue';

const props = defineProps({
    video: Object
});

const thumbnailUrl = computed(() => `/api/thumbnail/${props.video.path}`);
</script>

<template>
    <article class="card">
        <div class="thumbnail">
            <img :src="thumbnailUrl" :alt="video.name" loading="lazy" />
            <div class="overlay">
                <svg viewBox="0 0 24 24" fill="currentColor">
                    <path d="M8 5v14l11-7z"/>
                </svg>
            </div>
        </div>
        <h3>{{ video.name }}</h3>
    </article>
</template>

<style scoped>
.card {
    flex-shrink: 0;
    width: 240px;
    cursor: pointer;
    scroll-snap-align: start;
    transition: transform var(--transition);
}

.card:hover {
    transform: scale(1.05);
    z-index: 10;
}

.thumbnail {
    position: relative;
    aspect-ratio: 16/9;
    border-radius: 4px;
    overflow: hidden;
    background: var(--bg-card);
}

.thumbnail img {
    width: 100%;
    height: 100%;
    object-fit: cover;
    transition: transform 0.3s ease;
}

.card:hover .thumbnail img {
    transform: scale(1.1);
}

.overlay {
    position: absolute;
    inset: 0;
    display: flex;
    align-items: center;
    justify-content: center;
    background: rgba(0,0,0,0.4);
    opacity: 0;
    transition: opacity var(--transition);
}

.card:hover .overlay {
    opacity: 1;
}

.overlay svg {
    width: 48px;
    height: 48px;
    color: white;
    filter: drop-shadow(0 2px 8px rgba(0,0,0,0.5));
}

h3 {
    margin-top: 10px;
    font-size: 0.9rem;
    font-weight: 500;
    color: var(--text-secondary);
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    transition: color var(--transition);
}

.card:hover h3 {
    color: var(--text-primary);
}
</style>
