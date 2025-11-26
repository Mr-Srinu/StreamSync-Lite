// src/data-source.ts
import 'reflect-metadata';
import { DataSource } from 'typeorm';
import dotenv from 'dotenv';
import { User } from './entities/User.js';
import { Video } from './entities/Video.js';
import { VideoProgress } from './entities/VideoProgress.js';
import { Notification } from './entities/Notification.js';
import { FcmToken } from './entities/FcmToken.js';

dotenv.config();

export const AppDataSource = new DataSource({
  type: 'mysql',
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT || 3306),
  username: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  entities: [User, Video, VideoProgress, Notification, FcmToken],
  synchronize: true, // dev only
  logging: false,
});
