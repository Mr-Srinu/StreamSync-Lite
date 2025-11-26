import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  Unique,
  type Relation,
} from 'typeorm';
import { User } from './User.js';

@Entity({ name: 'fcm_tokens' })
@Unique(['user', 'token'])
export class FcmToken {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @ManyToOne(() => User, (user) => user.fcmTokens, {
    onDelete: 'CASCADE',
  })
  user!: Relation<User>;

  @Column({ type: 'varchar', length: 500 })
  token!: string;

  @Column({ type: 'varchar', length: 20 })
  platform!: string; // e.g. "android", "ios", "web"

  @Column({
    type: 'datetime',
    default: () => 'CURRENT_TIMESTAMP',
  })
  createdAt!: Date;
}
