return {
  source_dir = 'src',
  build_dir = 'lua',
  include_dir = { 'types' },
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
