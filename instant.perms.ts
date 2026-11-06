// InstantDB permissions for G-spend (expense).
// Push command and self-hosted endpoints: see instant/README.md.
//
// Ports the app's former client-side "granular push authorization" to the
// server. Membership checks traverse the links declared in instant.schema.ts
// via data.ref(...). Default (no rule) is allow-all, so every namespace below
// is locked down explicitly.

import type { InstantRules } from '@instantdb/core';

const rules = {
  $files: {
    bind: ['isUploader', "auth.id != null && data.path.startsWith(auth.id + '/')", 'canReadExpense', "auth.id != null && (auth.id in data.ref('expense.creator.id') || auth.id in data.ref('expense.project.owner.id') || auth.id in data.ref('expense.project.members.user.id'))", 'canEditExpense', "auth.id != null && (auth.id in data.ref('expense.creator.id') || auth.id in data.ref('expense.project.owner.id'))"],
    allow: {view: 'isUploader || canReadExpense', create: 'isUploader', update: 'isUploader || canEditExpense', delete: 'isUploader || canEditExpense'},
  },
  profiles: {
    // Any signed-in user can read profiles (needed for member search/sharing).
    allow: {
      view: 'auth.id != null',
      create: 'auth.id != null && auth.id == data.id',
      update: 'auth.id != null && auth.id == data.id',
      delete: 'auth.id != null && auth.id == data.id',
    },
  },

  projects: {
    allow: {
      // Owner or a member may view.
      view: "auth.id != null && (auth.id == data.ownerId || auth.id in data.ref('members.user.id'))",
      create: 'auth.id != null && auth.id == data.ownerId',
      update: 'auth.id != null && auth.id == data.ownerId',
      delete: 'auth.id != null && auth.id == data.ownerId',
    },
  },

  members: {
    allow: {
      // Project owner manages membership; a user can see their own membership.
      view: "auth.id != null && (auth.id == data.userId || auth.id in data.ref('project.owner.id'))",
      create: "auth.id != null && auth.id in data.ref('project.owner.id')",
      update: "auth.id != null && auth.id in data.ref('project.owner.id')",
      delete: "auth.id != null && auth.id in data.ref('project.owner.id')",
    },
  },

  categories: {
    allow: {
      // Global defaults (no owner) are readable by all; own categories by owner.
      view: 'auth.id != null && (data.ownerId == null || auth.id == data.ownerId)',
      create: 'auth.id != null && auth.id == data.ownerId',
      update: 'auth.id != null && auth.id == data.ownerId',
      delete: 'auth.id != null && auth.id == data.ownerId',
    },
  },

  expenses: {
    bind: [
      'isCreator', 'auth.id != null && auth.id == data.creatorId',
      'isProjectOwner', "auth.id != null && auth.id in data.ref('project.owner.id')",
      'isProjectMember', "auth.id != null && auth.id in data.ref('project.members.user.id')",
    ],
    allow: {
      // Creator, project owner, or a project member may view.
      view: 'isCreator || isProjectOwner || isProjectMember',
      // Must create as yourself.
      create: 'isCreator',
      // Creator or project owner may edit/remove.
      update: 'isCreator || isProjectOwner',
      delete: 'isCreator || isProjectOwner',
    },
  },
} satisfies InstantRules;

export default rules;
