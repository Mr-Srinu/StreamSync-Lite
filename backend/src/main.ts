// src/main.ts
import 'reflect-metadata';
import express, { Request, Response } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import dotenv from 'dotenv';
import { z } from 'zod';
import crypto from 'crypto';

import { AppDataSource } from './data-source.js';
import { User } from './entities/User.js';
import { Video } from './entities/Video.js';
import { VideoProgress } from './entities/VideoProgress.js';
import { Notification } from './entities/Notification.js';
import { FcmToken } from './entities/FcmToken.js';

dotenv.config();

const app = express();
app.use(helmet());
app.use(cors());
app.use(express.json());

const PORT = Number(process.env.PORT || 3000);

// ---------- Health ----------

app.get('/health', (_req: Request, res: Response) => {
  res.json({ status: 'ok', uptime: process.uptime() });
});

// ---------- Auth ----------

const registerSchema = z.object({
  name: z.string().min(1),
  email: z.string().email(),
  password: z.string().min(4),
});

app.post('/auth/register', async (req: Request, res: Response) => {
  try {
    const parsed = registerSchema.parse(req.body);

    const userRepo = AppDataSource.getRepository(User);
    const existing = await userRepo.findOne({ where: { email: parsed.email } });
    if (existing) {
      return res.status(400).json({ message: 'Email already registered' });
    }

    const user = userRepo.create({
      name: parsed.name,
      email: parsed.email,
      password: parsed.password, // TODO: hash in real app
    });
    await userRepo.save(user);

    return res.json({
      user: { id: user.id, name: user.name, email: user.email },
      accessToken: 'demo-token-' + user.id,
    });
  } catch (e: any) {
    if (e instanceof z.ZodError) {
      return res
        .status(400)
        .json({ message: 'Invalid payload', errors: e.errors });
    }
    console.error(e);
    return res.status(500).json({ message: 'Register failed' });
  }
});

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(4),
});

app.post('/auth/login', async (req: Request, res: Response) => {
  try {
    const parsed = loginSchema.parse(req.body);

    const userRepo = AppDataSource.getRepository(User);
    const user = await userRepo.findOne({
      where: { email: parsed.email, password: parsed.password },
    });

    if (!user) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    return res.json({
      user: { id: user.id, name: user.name, email: user.email },
      accessToken: 'demo-token-' + user.id,
    });
  } catch (e: any) {
    if (e instanceof z.ZodError) {
      return res
        .status(400)
        .json({ message: 'Invalid payload', errors: e.errors });
    }
    console.error(e);
    return res.status(500).json({ message: 'Login failed' });
  }
});

// ---------- FCM Tokens ----------

const fcmTokenSchema = z.object({
  token: z.string().min(10),
  platform: z.string().default('android'),
});

app.post('/users/:id/fcmToken', async (req: Request, res: Response) => {
  try {
    const userId = req.params.id;
    const parsed = fcmTokenSchema.parse(req.body);

    const userRepo = AppDataSource.getRepository(User);
    const tokenRepo = AppDataSource.getRepository(FcmToken);

    const user = await userRepo.findOne({ where: { id: userId } });
    if (!user) return res.status(404).json({ message: 'User not found' });

    let existing = await tokenRepo.findOne({
      where: { user: { id: userId }, token: parsed.token },
      relations: { user: true },
    });

    if (!existing) {
      const newToken = tokenRepo.create({
        user,
        token: parsed.token,
        platform: parsed.platform,
        createdAt: new Date(),
      });
      existing = await tokenRepo.save(newToken);
    }

    res.json({ success: true, token: existing });
  } catch (e: any) {
    if (e instanceof z.ZodError) {
      return res
        .status(400)
        .json({ message: 'Invalid payload', errors: e.errors });
    }
    console.error(e);
    res.status(500).json({ message: 'Failed to save FCM token' });
  }
});

// ---------- Videos ----------

app.get('/videos/latest', async (_req: Request, res: Response) => {
  try {
    const videoRepo = AppDataSource.getRepository(Video);

    // Always ensure the 10 demo videos exist
    const seedVideos = [
      {
        videoId: 'dQw4w9WgXcQ',
        title: 'Never Gonna Give You Up',
        description: 'Official music video.',
        thumbnailUrl:
            'https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
        channelId: 'channel-1',
        channelTitle: 'Classic Hits',
        publishedAt: new Date('2009-10-25T00:00:00Z'),
        durationSeconds: 215,
      },
      {
        videoId: '3JZ_D3ELwOQ',
        title: 'Best of LoFi Beats',
        description: 'Relax and study with lofi beats.',
        thumbnailUrl:
            'https://img.youtube.com/vi/3JZ_D3ELwOQ/hqdefault.jpg',
        channelId: 'channel-2',
        channelTitle: 'LoFi Station',
        publishedAt: new Date('2021-01-01T00:00:00Z'),
        durationSeconds: 3600,
      },
      {
        videoId: 'V-_O7nl0Ii0',
        title: 'Top 10 Coding Tips',
        description: 'Improve your coding skills quickly.',
        thumbnailUrl:
            'https://img.youtube.com/vi/V-_O7nl0Ii0/hqdefault.jpg',
        channelId: 'channel-3',
        channelTitle: 'CodeCraft',
        publishedAt: new Date('2022-01-10T00:00:00Z'),
        durationSeconds: 900,
      },
      {
        videoId: 'kXYiU_JCYtU',
        title: 'Numb (Official Video)',
        description: 'Linkin Park official video.',
        thumbnailUrl:
            'https://img.youtube.com/vi/kXYiU_JCYtU/hqdefault.jpg',
        channelId: 'channel-4',
        channelTitle: 'Rock Legends',
        publishedAt: new Date('2007-03-10T00:00:00Z'),
        durationSeconds: 185,
      },
      {
        videoId: 'e-ORhEE9VVg',
        title: 'Taylor Swift - Blank Space',
        description: 'Official music video.',
        thumbnailUrl:
            'https://img.youtube.com/vi/e-ORhEE9VVg/hqdefault.jpg',
        channelId: 'channel-5',
        channelTitle: 'Pop Central',
        publishedAt: new Date('2014-11-10T00:00:00Z'),
        durationSeconds: 240,
      },
      {
        videoId: 'M7lc1UVf-VE',
        title: 'YouTube IFrame Player API Demo',
        description: 'Official YouTube API demo video.',
        thumbnailUrl:
            'https://img.youtube.com/vi/M7lc1UVf-VE/hqdefault.jpg',
        channelId: 'channel-6',
        channelTitle: 'YouTube Dev',
        publishedAt: new Date('2018-05-03T00:00:00Z'),
        durationSeconds: 300,
      },
      {
        videoId: 'L_jWHffIx5E',
        title: 'Smash Mouth - All Star',
        description: 'Official video.',
        thumbnailUrl:
            'https://img.youtube.com/vi/L_jWHffIx5E/hqdefault.jpg',
        channelId: 'channel-7',
        channelTitle: '90s Vibes',
        publishedAt: new Date('2009-06-16T00:00:00Z'),
        durationSeconds: 200,
      },
      {
        videoId: 'ZZ5LpwO-An4',
        title: 'He-Man Sings',
        description: 'Parody music video.',
        thumbnailUrl:
            'https://img.youtube.com/vi/ZZ5LpwO-An4/hqdefault.jpg',
        channelId: 'channel-8',
        channelTitle: 'Meme Classics',
        publishedAt: new Date('2010-01-01T00:00:00Z'),
        durationSeconds: 210,
      },
      {
        videoId: '9bZkp7q19f0',
        title: 'PSY - GANGNAM STYLE',
        description: 'Official music video.',
        thumbnailUrl:
            'https://img.youtube.com/vi/9bZkp7q19f0/hqdefault.jpg',
        channelId: 'channel-9',
        channelTitle: 'K-Pop World',
        publishedAt: new Date('2012-07-15T00:00:00Z'),
        durationSeconds: 252,
      },
      {
        videoId: '2Vv-BfVoq4g',
        title: 'Ed Sheeran - Perfect',
        description: 'Official video.',
        thumbnailUrl:
            'https://img.youtube.com/vi/2Vv-BfVoq4g/hqdefault.jpg',
        channelId: 'channel-10',
        channelTitle: 'Soft Pop',
        publishedAt: new Date('2017-11-09T00:00:00Z'),
        durationSeconds: 265,
      },
    ];

    // Upsert-style: insert missing videos by videoId
    for (const s of seedVideos) {
      const exists = await videoRepo.findOne({
        where: { videoId: s.videoId },
      });
      if (!exists) {
        const entity = videoRepo.create({
          videoId: s.videoId!,
          title: s.title!,
          description: s.description ?? null,
          thumbnailUrl: s.thumbnailUrl!,
          channelId: s.channelId!,
          channelTitle: s.channelTitle ?? null,
          publishedAt: s.publishedAt ?? new Date(),
          durationSeconds: s.durationSeconds ?? 0,
        });
        await videoRepo.save(entity);
      }
    }

    const items = await videoRepo.find({
      order: { publishedAt: 'DESC' },
      take: 10,
    });

    res.json({ items });
  } catch (e) {
    console.error(e);
    res.status(500).json({ message: 'Failed to load videos' });
  }
});



app.get('/videos/:videoId', async (req: Request, res: Response) => {
  try {
    const videoId = req.params.videoId;
    const userId = (req.query.userId as string) || null;

    const videoRepo = AppDataSource.getRepository(Video);
    const progressRepo = AppDataSource.getRepository(VideoProgress);

    const video = await videoRepo.findOne({ where: { videoId } });
    if (!video) return res.status(404).json({ message: 'Not found' });

    let progress: VideoProgress | null = null;
    if (userId) {
      progress = await progressRepo.findOne({
        where: {
          user: { id: userId },
          video: { videoId },
        },
        relations: { user: true, video: true },
      });
    }

    res.json({
      videoId: video.videoId,
      title: video.title,
      description: video.description,
      thumbnailUrl: video.thumbnailUrl,
      channelId: video.channelId,
      channelTitle: video.channelTitle,
      publishedAt: video.publishedAt,
      durationSeconds: video.durationSeconds,
      progress: progress
        ? {
            positionSeconds: progress.positionSeconds,
            completedPercent: progress.completedPercent,
            updatedAt: progress.updatedAt,
          }
        : null,
    });
  } catch (e) {
    console.error(e);
    res.status(500).json({ message: 'Failed to load video' });
  }
});

// ---------- Video Progress ----------

const progressSchema = z.object({
  userId: z.string().uuid(),
  videoId: z.string().min(3),
  positionSeconds: z.number().int().nonnegative(),
  completedPercent: z.number().min(0).max(100),
  updatedAt: z.string().optional(), // ISO
});

app.post('/videos/progress', async (req: Request, res: Response) => {
  try {
    const parsed = progressSchema.parse(req.body);

    const userRepo = AppDataSource.getRepository(User);
    const videoRepo = AppDataSource.getRepository(Video);
    const progressRepo = AppDataSource.getRepository(VideoProgress);

    const user = await userRepo.findOne({ where: { id: parsed.userId } });
    if (!user) return res.status(404).json({ message: 'User not found' });

    const video = await videoRepo.findOne({ where: { videoId: parsed.videoId } });
    if (!video) return res.status(404).json({ message: 'Video not found' });

    const now = parsed.updatedAt ? new Date(parsed.updatedAt) : new Date();

    let existing = await progressRepo.findOne({
      where: { user: { id: parsed.userId }, video: { videoId: parsed.videoId } },
      relations: { user: true, video: true },
    });

    if (existing) {
      existing.positionSeconds = parsed.positionSeconds;
      existing.completedPercent = parsed.completedPercent;
      existing.updatedAt = now;
      await progressRepo.save(existing);
    } else {
      const prog = progressRepo.create({
        user,
        video,
        positionSeconds: parsed.positionSeconds,
        completedPercent: parsed.completedPercent,
        updatedAt: now,
      });
      await progressRepo.save(prog);
    }

    res.json({ success: true });
  } catch (e: any) {
    if (e instanceof z.ZodError) {
      return res
        .status(400)
        .json({ message: 'Invalid payload', errors: e.errors });
    }
    console.error(e);
    res.status(500).json({ message: 'Failed to save progress' });
  }
});

// ---------- Notifications ----------

app.get('/notifications', async (req: Request, res: Response) => {
  try {
    const userId = (req.query.userId as string) || '1';

    const notifRepo = AppDataSource.getRepository(Notification);
    const items = await notifRepo.find({
      where: { user: { id: userId }, deleted: false },
      order: { createdAt: 'DESC' },
      relations: { user: true },
    });

    const result = items.map((n) => ({
      id: n.id,
      title: n.title,
      body: n.body,
      createdAt: n.createdAt,
      isRead: n.isRead,
      deleted: n.deleted,
    }));

    res.json({ items: result });
  } catch (e) {
    console.error(e);
    res.status(500).json({ message: 'Failed to load notifications' });
  }
});

// Simple in-memory maps for rate limiting + idempotency (dev only)
const testPushRateLimit = new Map<string, number>(); // userId -> last timestamp
const testPushIdempotency = new Set<string>(); // idempotencyKey

const sendTestNotifSchema = z.object({
  userId: z.string().uuid().optional(),
  title: z.string().optional(),
  body: z.string().optional(),
  mode: z.enum(['self']).default('self'),
  idempotencyKey: z.string().optional(),
});

app.post('/notifications/send-test', async (req: Request, res: Response) => {
  try {
    const parsed = sendTestNotifSchema.parse(req.body);
    const userId = parsed.userId ?? '1';

    // Rate limit: 1 per 10 seconds per user
    const now = Date.now();
    const last = testPushRateLimit.get(userId) ?? 0;
    const windowMs = 10_000;
    if (now - last < windowMs) {
      return res.status(429).json({
        message: 'Too many test pushes. Please wait a bit and try again.',
      });
    }

    // Idempotency
    const idKey =
      parsed.idempotencyKey ??
      crypto.createHash('sha256').update(`${userId}:${now}`).digest('hex');

    if (testPushIdempotency.has(idKey)) {
      return res.json({
        success: true,
        message: 'Duplicate idempotent request ignored.',
        idempotencyKey: idKey,
      });
    }

    testPushIdempotency.add(idKey);
    testPushRateLimit.set(userId, now);

    const userRepo = AppDataSource.getRepository(User);
    const notifRepo = AppDataSource.getRepository(Notification);

    const user = await userRepo.findOne({ where: { id: userId } });
    if (!user) return res.status(404).json({ message: 'User not found' });

    const notif = notifRepo.create({
      user,
      title: parsed.title || 'Test Push',
      body: parsed.body || 'Hello from StreamSync Lite',
      createdAt: new Date(),
      isRead: false,
      deleted: false,
    });
    await notifRepo.save(notif);

    // TODO: enqueue notification_jobs for Firebase worker here

    res.json({
      success: true,
      notification: {
        id: notif.id,
        title: notif.title,
        body: notif.body,
        createdAt: notif.createdAt,
      },
      idempotencyKey: idKey,
    });
  } catch (e: any) {
    if (e instanceof z.ZodError) {
      return res
        .status(400)
        .json({ message: 'Invalid payload', errors: e.errors });
    }
    console.error(e);
    res.status(500).json({ message: 'Failed to send test notification' });
  }
});

const markReadSchema = z.object({
  ids: z.array(z.string().uuid()).default([]),
  userId: z.string().uuid().optional(),
});

app.post('/notifications/mark-read', async (req: Request, res: Response) => {
  try {
    const parsed = markReadSchema.parse(req.body);
    const ids = parsed.ids;
    const userId = parsed.userId ?? '1';

    if (!ids.length) return res.json({ success: true });

    const notifRepo = AppDataSource.getRepository(Notification);
    await notifRepo
      .createQueryBuilder()
      .update(Notification)
      .set({ isRead: true })
      .where('id IN (:...ids)', { ids })
      .andWhere('userId = :userId', { userId })
      .execute();

    res.json({ success: true });
  } catch (e: any) {
    if (e instanceof z.ZodError) {
      return res
        .status(400)
        .json({ message: 'Invalid payload', errors: e.errors });
    }
    console.error(e);
    res.status(500).json({ message: 'Failed to mark notifications read' });
  }
});

app.delete('/notifications/:id', async (req: Request, res: Response) => {
  try {
    const id = req.params.id;
    const notifRepo = AppDataSource.getRepository(Notification);

    await notifRepo
      .createQueryBuilder()
      .update(Notification)
      .set({ deleted: true })
      .where('id = :id', { id })
      .execute();

    res.json({ success: true });
  } catch (e) {
    console.error(e);
    res.status(500).json({ message: 'Failed to delete notification' });
  }
});

// ---------- Start server after DB init ----------

AppDataSource.initialize()
  .then(() => {
    console.log('MySQL Data Source has been initialized.');
    app.listen(PORT, () => {
      console.log(`Backend listening on port ${PORT}`);
    });
  })
  .catch((err) => {
    console.error('Error during Data Source initialization:', err);
  });
