const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const config = require('../../config');
const db = require('../../db/store');
const { AppError } = require('../../middleware/error.middleware');

class AuthService {
  async register({ name, email, password, role }) {
    const usersCol = db.collection('users');
    const existing = usersCol.findOne((u) => u.email.toLowerCase() === email.toLowerCase());

    if (existing) {
      throw new AppError('An account with this email already exists', 400);
    }

    if (role === 'admin') {
      throw new AppError('Admin accounts cannot be self-registered', 403);
    }

    const validRoles = ['teacher', 'student', 'parent'];
    const assignedRole = validRoles.includes(role) ? role : 'student';

    const hashedPassword = await bcrypt.hash(password, 10);
    const approved = false; // Requires administrator approval

    const user = usersCol.insert({
      name,
      email: email.toLowerCase(),
      password: hashedPassword,
      role: assignedRole,
      approved,
      photoUrl: '',
    });

    // Create role-specific record
    if (assignedRole === 'student') {
      db.collection('students').insert({
        id: user.id,
        uid: user.id,
        name,
        email: email.toLowerCase(),
        rollNo: '',
        class: '',
        section: '',
        contact: '',
        approved,
      });
    } else if (assignedRole === 'teacher') {
      db.collection('teachers').insert({
        id: user.id,
        uid: user.id,
        name,
        email: email.toLowerCase(),
        phone: '',
        subject: '',
        qualification: '',
        classes: [],
        approved,
      });
    } else if (assignedRole === 'parent') {
      db.collection('parents').insert({
        id: user.id,
        uid: user.id,
        name,
        email: email.toLowerCase(),
        approved,
      });
    }

    const token = this._generateToken(user);

    return {
      user: this._sanitizeUser(user),
      token,
    };
  }

  async login({ email, password }) {
    const usersCol = db.collection('users');
    const user = usersCol.findOne((u) => u.email.toLowerCase() === email.toLowerCase());

    if (!user) {
      throw new AppError('Invalid email or password', 401);
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      throw new AppError('Invalid email or password', 401);
    }

    const token = this._generateToken(user);

    return {
      user: this._sanitizeUser(user),
      token,
    };
  }

  async getProfile(userId) {
    const usersCol = db.collection('users');
    const user = usersCol.findById(userId);

    if (!user) {
      throw new AppError('User not found', 404);
    }

    return this._sanitizeUser(user);
  }

  _generateToken(user) {
    return jwt.sign(
      {
        id: user.id,
        uid: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        approved: user.approved,
      },
      config.jwt.secret,
      { expiresIn: config.jwt.expiresIn }
    );
  }

  _sanitizeUser(user) {
    const { password, ...sanitized } = user;
    return sanitized;
  }
}

module.exports = new AuthService();
