// src/entities/Video.ts
import { Entity, PrimaryColumn, Column, OneToMany } from 'typeorm';
import { VideoProgress } from './VideoProgress.js';

@Entity({ name: 'videos' })
export class Video {
  @PrimaryColumn({ type: 'varchar', length: 32 })
  videoId!: string; // YouTube ID

  @Column({ type: 'varchar', length: 300 })
  title!: string;

  @Column({ type: 'text', nullable: true })
  description!: string | null;

  @Column({ type: 'varchar', length: 500 })
  thumbnailUrl!: string;

  @Column({ type: 'varchar', length: 120 })
  channelId!: string;

  @Column({ type: 'varchar', length: 200, nullable: true })
  channelTitle!: string | null;

  @Column({ type: 'datetime' })
  publishedAt!: Date;

  @Column({ type: 'int', default: 0 })
  durationSeconds!: number;

  @OneToMany(() => VideoProgress, (p) => p.video)
  progress!: VideoProgress[];
}
