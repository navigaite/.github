import { defineConfig } from '@navigaite/eslint-config';

export default defineConfig(
  {
    prettier: false,
    typescript: true,
    ignores: ['./src/components/common/shadcn/*.tsx', 'scripts/*.ts'],
  },
  {
    rules: {
      'no-return-await': 'off',
    },
  },
);
