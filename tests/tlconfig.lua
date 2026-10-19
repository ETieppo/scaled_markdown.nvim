return {
  source_dir = '.',
  build_dir = 'build',
  include_dir = { '../src', '../types' },
  global_env_def = 'vim',
  gen_target = '5.1',
  gen_compat = 'off',
  feat_arity = 'on',
  warning_error = {
    'unknown',
    'unused',
    'redeclaration',
    'branch',
    'hint',
    'debug',
    'unread',
  },
}
