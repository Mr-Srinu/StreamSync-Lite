// src/entities/User.ts
import { Entity, PrimaryGeneratedColumn, Column, OneToMany } from 'typeorm';
import { FcmToken } from './FcmToken.js';
import { VideoProgress } from './VideoProgress.js';
import { Notification } from './Notification.js';

@Entity({ name: 'users' })
export class User {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'varchar', length: 120 })
  name!: string;

  @Column({ type: 'varchar', length: 200, unique: true })
  email!: string;

  @Column({ type: 'varchar', length: 200 })
  password!: string; // TODO: hash in production

  @OneToMany(() => FcmToken, (t) => t.user)
  fcmTokens!: FcmToken[];

  @OneToMany(() => VideoProgress, (p) => p.user)
  progress!: VideoProgress[];

  @OneToMany(() => Notification, (n) => n.user)
  notifications!: Notification[];
}
