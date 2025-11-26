// src/entities/FcmToken.ts
import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  Unique,
} from 'typeorm';
import { User } from './User.js';

@Entity({ name: 'fcm_tokens' })
@Unique(['user', 'token'])
export class FcmToken {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @ManyToOne(() => User, (u) => u.fcmTokens, { eager: false })
  user!: User;

  @Column({ type: 'varchar', length: 500 })
  token!: string;

  @Column({ type: 'varchar', length: 20 })
  platform!: string;

  @Column({ type: 'datetime' })
  createdAt!: Date;
}
