import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  OneToMany,
  type Relation,
} from 'typeorm';
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
  password!: string; // store hashed password in production

  @OneToMany(() => FcmToken, (token) => token.user)
  fcmTokens!: Relation<FcmToken[]>;

  @OneToMany(() => VideoProgress, (progress) => progress.user)
  progress!: Relation<VideoProgress[]>;

  @OneToMany(() => Notification, (notification) => notification.user)
  notifications!: Relation<Notification[]>;
}
