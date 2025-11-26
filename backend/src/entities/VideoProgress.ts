import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  Unique,
  type Relation,
} from 'typeorm';
import { User } from './User.js';
import { Video } from './Video.js';

@Entity({ name: 'video_progress' })
@Unique(['user', 'video'])
export class VideoProgress {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @ManyToOne(() => User, (user) => user.progress, {
    onDelete: 'CASCADE',
  })
  user!: Relation<User>;

  @ManyToOne(() => Video, (video) => video.progress, {
    onDelete: 'CASCADE',
  })
  video!: Relation<Video>;

  // Last watched position in seconds (or any unit you use)
  @Column({ type: 'int', default: 0 })
  lastPosition!: number;

  // Percentage watched (0–100) if you track it
  @Column({ type: 'float', default: 0 })
  progressPercent!: number;

  @Column({ type: 'boolean', default: false })
  completed!: boolean;

  @Column({
    type: 'datetime',
    default: () => 'CURRENT_TIMESTAMP',
  })
  updatedAt!: Date;
}
