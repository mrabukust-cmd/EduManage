const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

class DatabaseStore {
  constructor(filePath = null) {
    this.filePath = filePath || path.resolve(__dirname, '../../data/edumanage.db.json');
    this.collections = {
      users: [],
      classes: [],
      students: [],
      teachers: [],
      parents: [],
      parent_children: [],
      attendance: [],
      assignments: [],
      fees: [],
      notices: [],
      timetable: [],
      results: [],
    };

    this._ensureDirectory();
    this._load();
  }

  _ensureDirectory() {
    const dir = path.dirname(this.filePath);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
  }

  _load() {
    try {
      if (fs.existsSync(this.filePath)) {
        const raw = fs.readFileSync(this.filePath, 'utf8');
        const parsed = JSON.parse(raw);
        this.collections = { ...this.collections, ...parsed };
      } else {
        this._save();
      }
    } catch (e) {
      console.warn('[DatabaseStore] Could not load database file, initialized fresh store:', e.message);
      this._save();
    }
  }

  _save() {
    try {
      fs.writeFileSync(this.filePath, JSON.stringify(this.collections, null, 2), 'utf8');
    } catch (e) {
      console.error('[DatabaseStore] Error saving database file:', e.message);
    }
  }

  collection(name) {
    if (!this.collections[name]) {
      this.collections[name] = [];
    }
    return {
      find: (predicate = () => true) => {
        return this.collections[name].filter(predicate);
      },

      findOne: (predicate) => {
        return this.collections[name].find(predicate) || null;
      },

      findById: (id) => {
        return this.collections[name].find((item) => item.id === id || item.uid === id) || null;
      },

      insert: (doc) => {
        const id = doc.id || doc.uid || `doc_${crypto.randomBytes(8).toString('hex')}`;
        const timestamp = new Date().toISOString();
        const newDoc = {
          ...doc,
          id,
          createdAt: doc.createdAt || timestamp,
          updatedAt: timestamp,
        };
        this.collections[name].push(newDoc);
        this._save();
        return newDoc;
      },

      update: (id, updates) => {
        const index = this.collections[name].findIndex(
          (item) => item.id === id || item.uid === id
        );
        if (index === -1) return null;

        const updatedDoc = {
          ...this.collections[name][index],
          ...updates,
          updatedAt: new Date().toISOString(),
        };
        this.collections[name][index] = updatedDoc;
        this._save();
        return updatedDoc;
      },

      delete: (id) => {
        const index = this.collections[name].findIndex(
          (item) => item.id === id || item.uid === id
        );
        if (index === -1) return false;

        this.collections[name].splice(index, 1);
        this._save();
        return true;
      },

      count: (predicate = () => true) => {
        return this.collections[name].filter(predicate).length;
      },

      clear: () => {
        this.collections[name] = [];
        this._save();
      }
    };
  }
}

const db = new DatabaseStore();

module.exports = db;
