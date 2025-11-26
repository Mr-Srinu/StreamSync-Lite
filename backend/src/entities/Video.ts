import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  OneToMany,
  type Relation,
} from 'typeorm';
import { VideoProgress } from './VideoProgress.js';

@Entity({ name: 'videos' })
export class Video {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'varchar', length: 200 })
  title!: string;

  @Column({ type: 'varchar', length: 500 })
  description!: string;

  @Column({ type: 'varchar', length: 500 })
  url!: string;

  @Column({ type: 'int', default: 0 })
  durationSeconds!: number;

  @Column({
    type: 'datetime',
    default: () => 'CURRENT_TIMESTAMP',
  })
  publishedAt!: Date;

  @OneToMany(() => VideoProgress, (progress) => progress.video)
  progress!: Relation<VideoProgress[]>;
}
