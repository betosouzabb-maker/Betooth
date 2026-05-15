const fs = require('fs');
const path = require('path');
const { env } = require('../config/env');

const DATA_DIR = env.NODE_ENV === 'production' ? './data' : './.tmp';
const DB_FILE = path.join(DATA_DIR, 'betooth.json');

if (!fs.existsSync(DATA_DIR)) {
  fs.mkdirSync(DATA_DIR, { recursive: true });
}

function loadDb() {
  if (fs.existsSync(DB_FILE)) {
    return JSON.parse(fs.readFileSync(DB_FILE, 'utf-8'));
  }
  return {
    users: [],
    user_sessions: [],
    devices: [],
    tracks: [],
    user_library: [],
    playlists: [],
    playlist_tracks: [],
    favorites: [],
    play_history: [],
    search_history: [],
    downloads: [],
    subscriptions: [],
    notifications: [],
  };
}

let db = loadDb();

function saveDb() {
  fs.writeFileSync(DB_FILE, JSON.stringify(db, null, 2));
}

function initDatabase() {
  if (db.tracks.length === 0) {
    db.tracks = [
      { id: 'track-1', title: 'Bohemian Rhapsody', artist: 'Queen', album: 'A Night at the Opera', genre: 'Rock', duration: 354, cover_url: 'https://i.scdn.co/image/ab67616d0000b273e8b066f70c206551210d902b', audio_url: 'https://example.com/audio1.mp3', file_size: null, bitrate: null, sample_rate: null, lyrics: null, is_explicit: 0, play_count: 0, download_count: 0, status: 'ACTIVE', uploaded_by: null, created_at: new Date().toISOString(), updated_at: new Date().toISOString() },
      { id: 'track-2', title: 'Hotel California', artist: 'Eagles', album: 'Hotel California', genre: 'Rock', duration: 391, cover_url: 'https://i.scdn.co/image/ab67616d0000b273b5d4c4c7c56f7b7e0e0d3b3b', audio_url: 'https://example.com/audio2.mp3', file_size: null, bitrate: null, sample_rate: null, lyrics: null, is_explicit: 0, play_count: 0, download_count: 0, status: 'ACTIVE', uploaded_by: null, created_at: new Date().toISOString(), updated_at: new Date().toISOString() },
      { id: 'track-3', title: 'Imagine', artist: 'John Lennon', album: 'Imagine', genre: 'Pop', duration: 183, cover_url: 'https://i.scdn.co/image/ab67616d0000b273b5d4c4c7c56f7b7e0e0d3b3b', audio_url: 'https://example.com/audio3.mp3', file_size: null, bitrate: null, sample_rate: null, lyrics: null, is_explicit: 0, play_count: 0, download_count: 0, status: 'ACTIVE', uploaded_by: null, created_at: new Date().toISOString(), updated_at: new Date().toISOString() },
      { id: 'track-4', title: 'Smells Like Teen Spirit', artist: 'Nirvana', album: 'Nevermind', genre: 'Grunge', duration: 301, cover_url: 'https://i.scdn.co/image/ab67616d0000b273b5d4c4c7c56f7b7e0e0d3b3b', audio_url: 'https://example.com/audio4.mp3', file_size: null, bitrate: null, sample_rate: null, lyrics: null, is_explicit: 0, play_count: 0, download_count: 0, status: 'ACTIVE', uploaded_by: null, created_at: new Date().toISOString(), updated_at: new Date().toISOString() },
      { id: 'track-5', title: 'Billie Jean', artist: 'Michael Jackson', album: 'Thriller', genre: 'Pop', duration: 294, cover_url: 'https://i.scdn.co/image/ab67616d0000b273b5d4c4c7c56f7b7e0e0d3b3b', audio_url: 'https://example.com/audio5.mp3', file_size: null, bitrate: null, sample_rate: null, lyrics: null, is_explicit: 0, play_count: 0, download_count: 0, status: 'ACTIVE', uploaded_by: null, created_at: new Date().toISOString(), updated_at: new Date().toISOString() },
    ];
    saveDb();
  }
  console.log('[DB] JSON database initialized');
}

function findOne(table, predicate) {
  return db[table].find(predicate);
}

function findAll(table, predicate) {
  if (predicate) return db[table].filter(predicate);
  return [...db[table]];
}

function insert(table, item) {
  db[table].push(item);
  saveDb();
}

function update(table, predicate, updater) {
  const idx = db[table].findIndex(predicate);
  if (idx !== -1) {
    db[table][idx] = updater(db[table][idx]);
    saveDb();
  }
}

function remove(table, predicate) {
  db[table] = db[table].filter(item => !predicate(item));
  saveDb();
}

module.exports = { db, initDatabase, saveDb, findOne, findAll, insert, update, remove };
