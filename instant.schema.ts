// InstantDB schema for G-spend (expense).
// Push command and self-hosted endpoints: see instant/README.md.
//
// The Flutter client writes each relation BOTH as a scalar id attribute
// (creatorId, projectId, categoryId, ownerId, userId, invitedBy) — so it can
// filter with plain `where` clauses — AND as a real InstantDB link (creator,
// project, category, owner, user, invitedBy) which the permission rules in
// instant.perms.ts traverse with data.ref(...). Keep both in sync on write.

import { i } from '@instantdb/core';

const _schema = i.schema({
  entities: {
    $files: i.entity({path: i.string().unique().indexed(), url: i.string()}),
    // Built-in identity namespace.
    $users: i.entity({
      email: i.string().unique().indexed(),
    }),

    profiles: i.entity({
      name: i.string(),
      email: i.string().indexed(),
    }),

    projects: i.entity({
      ownerId: i.string().indexed(),
      name: i.string(),
      description: i.string().optional(),
      color: i.string().optional(),
      icon: i.string().optional(),
      isDefault: i.boolean(),
      createdAt: i.number(),
      updatedAt: i.number(),
    }),

    members: i.entity({
      projectId: i.string().indexed(),
      userId: i.string().indexed(),
      role: i.string(),
      invitedBy: i.string().optional(),
      invitedAt: i.number().optional(),
      acceptedAt: i.number().optional(),
    }),

    categories: i.entity({
      ownerId: i.string().optional().indexed(), // null == global default
      name: i.string(),
      icon: i.string().optional(),
      color: i.string().optional(),
      isDefault: i.boolean(),
      updatedAt: i.number(),
    }),

    expenses: i.entity({
      creatorId: i.string().indexed(),
      projectId: i.string().optional().indexed(), // null == personal
      categoryId: i.string().optional().indexed(),
      amount: i.number(),
      type: i.string(), // 'expense' | 'income'
      date: i.number().indexed(),
      note: i.string().optional(),
      createdAt: i.number(),
      updatedAt: i.number(),
    }),
  },

  links: {
    expenseFiles: {forward: {on: 'expenses', has: 'many', label: 'files'}, reverse: {on: '$files', has: 'one', label: 'expense'}},
    profileUser: {
      forward: { on: 'profiles', has: 'one', label: 'user' },
      reverse: { on: '$users', has: 'one', label: 'profile' },
    },
    projectOwner: {
      forward: { on: 'projects', has: 'one', label: 'owner' },
      reverse: { on: '$users', has: 'many', label: 'ownedProjects' },
    },
    memberProject: {
      forward: { on: 'members', has: 'one', label: 'project' },
      reverse: { on: 'projects', has: 'many', label: 'members' },
    },
    memberUser: {
      forward: { on: 'members', has: 'one', label: 'user' },
      reverse: { on: '$users', has: 'many', label: 'memberships' },
    },
    categoryOwner: {
      forward: { on: 'categories', has: 'one', label: 'owner' },
      reverse: { on: '$users', has: 'many', label: 'ownedCategories' },
    },
    expenseCreator: {
      forward: { on: 'expenses', has: 'one', label: 'creator' },
      reverse: { on: '$users', has: 'many', label: 'createdExpenses' },
    },
    expenseProject: {
      forward: { on: 'expenses', has: 'one', label: 'project' },
      reverse: { on: 'projects', has: 'many', label: 'expenses' },
    },
    expenseCategory: {
      forward: { on: 'expenses', has: 'one', label: 'category' },
      reverse: { on: 'categories', has: 'many', label: 'expenses' },
    },
  },

  rooms: {},
});

type _AppSchema = typeof _schema;
interface AppSchema extends _AppSchema {}
const schema: AppSchema = _schema;

export type { AppSchema };
export default schema;
