// src/entities/VideoProgress.ts
import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  Unique,
} from 'typeorm';
import type { Relation } from 'typeorm';
import { User } from './User.js';
import { Video } from './Video.js';

@Entity({ name: 'video_progress' })
@Unique(['user', 'video'])
export class VideoProgress {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @ManyToOne(() => User, (u) => u.progress, { eager: false })
  user!: Relation<User>;

  @ManyToOne(() => Video, (v) => v.progress, { eager: false })
  video!: Relation<Video>;

  @Column({ type: 'int', default: 0 })
  positionSeconds!: number;

  @Column({ type: 'float', default: 0 })
  completedPercent!: number;

  @Column({ type: 'datetime' })
  updatedAt!: Date;
}
