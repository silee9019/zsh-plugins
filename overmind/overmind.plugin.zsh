# shellcheck shell=bash
# shellcheck disable=SC2034,SC2119,SC2120,SC2152,SC2154,SC2296
# overmind: Zsh completion for Overmind v2.5.1
# zinit: zinit ice pick"overmind/overmind.plugin.zsh"; zinit light silee9019/zsh-plugins

_overmind_commands=(
  'start:Run procfile'
  's:Alias for start'
  'restart:Restart specified processes'
  'r:Alias for restart'
  'stop:Stop specified processes without quitting Overmind itself'
  'interrupt:Alias for stop'
  'i:Alias for stop'
  'connect:Connect to the tmux session of the specified process'
  'c:Alias for connect'
  'quit:Gracefully quit Overmind'
  'q:Alias for quit'
  'kill:Kill all processes'
  'k:Alias for kill'
  'run:Run a command within the Overmind environment'
  'exec:Alias for run'
  'e:Alias for run'
  'echo:Echo output from master Overmind instance'
  'status:Print process statuses'
  'ps:Alias for status'
)

_overmind_networks=(
  'unix:Unix socket'
  'tcp:TCP network'
  'tcp4:TCP IPv4 network'
  'tcp6:TCP IPv6 network'
)

_overmind_signals=(
  'ABRT'
  'INT'
  'KILL'
  'QUIT'
  'STOP'
  'TERM'
  'USR1'
  'USR2'
)

_overmind_canonical_command() {
  case "$1" in
    s) echo start ;;
    r) echo restart ;;
    interrupt | i) echo stop ;;
    c) echo connect ;;
    q) echo quit ;;
    k) echo kill ;;
    exec | e) echo run ;;
    ps) echo status ;;
    *) echo "$1" ;;
  esac
}

_overmind_procfile_path() {
  local i word next procfile

  for ((i = 1; i <= $#words; i++)); do
    word="${words[i]}"
    next="${words[i + 1]}"

    case "$word" in
      --procfile=*)
        procfile="${word#--procfile=}"
        ;;
      -f*)
        if [[ "$word" == "-f" ]]; then
          procfile="$next"
        else
          procfile="${word#-f}"
        fi
        ;;
      --procfile)
        procfile="$next"
        ;;
    esac
  done

  print -r -- "${procfile:-${OVERMIND_PROCFILE:-./Procfile}}"
}

_overmind_process_names() {
  local procfile line name
  local -a names

  procfile="$(_overmind_procfile_path)"
  [[ -r "$procfile" ]] || return 1

  while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]*([A-Za-z0-9_.-]+)[[:space:]]*: ]]; then
      name="${match[1]}"
      names+=("$name")
    fi
  done <"$procfile"

  (( ${#names} )) || return 1
  print -rl -- "${(@u)names}"
}

_overmind_processes() {
  local -a processes

  processes=("${(@f)$(_overmind_process_names 2>/dev/null)}")
  if (( ${#processes} )); then
    _describe -t processes 'process' processes
  else
    _message 'No readable Procfile found'
  fi
}

_overmind_process_list() {
  local -a processes values

  processes=("${(@f)$(_overmind_process_names 2>/dev/null)}")
  values=("${processes[@]}")
  (( ${#values} )) || return 1

  _values -s , 'process' "${values[@]}"
}

_overmind_process_list_with_all() {
  local -a processes values

  processes=("${(@f)$(_overmind_process_names 2>/dev/null)}")
  values=('all:All processes' "${processes[@]}")

  _values -s , 'process' "${values[@]}"
}

_overmind_formation_list() {
  local -a processes values

  processes=("${(@f)$(_overmind_process_names 2>/dev/null)}")
  values=('all=:Set instance count for all processes' "${(@)^processes}=:[instance count]")

  _values -s , 'formation' "${values[@]}"
}

_overmind_stop_signal_list() {
  local -a processes values signal_specs

  processes=("${(@f)$(_overmind_process_names 2>/dev/null)}")
  signal_specs=("${(@)^_overmind_signals}:signal")
  values=("${(@)^processes}=:[signal:(${(j: :)_overmind_signals})]")

  if (( ${#values} )); then
    _values -s , 'stop signal' "${values[@]}"
  else
    _values -s , 'signal' "${signal_specs[@]}"
  fi
}

_overmind_colors() {
  _message 'xterm color code list, separated by commas'
}

_overmind_shells() {
  _command_names -e
}

_overmind_common_options=(
  '(-s --socket)'{-s,--socket}'[path to overmind socket or address to bind]:socket:_files'
  '(-S --network)'{-S,--network}'[network to use for commands]:network:->network'
)

_overmind_start_options=(
  '(-w --title)'{-w,--title}'[specify a title of the application]:title:'
  '(-f --procfile)'{-f,--procfile}'[specify a Procfile to load]:Procfile:_files'
  '(-l --processes)'{-l,--processes}'[process names to launch, separated by commas]:processes:_overmind_process_list'
  '(-d --root)'{-d,--root}'[working directory of application]:directory:_files -/'
  '(-t --timeout)'{-t,--timeout}'[seconds processes have to shut down gracefully]:seconds:'
  '(-p --port)'{-p,--port}'[base port]:port:'
  '(-P --port-step)'{-P,--port-step}'[step to increase port number]:port step:'
  '(-N --no-port)'{-N,--no-port}"[do not set \$PORT variable for processes]"
  '(-c --can-die)'{-c,--can-die}'[processes which can die without interrupting others]:processes:_overmind_process_list'
  '--any-can-die[allow any dead process without stopping Overmind]'
  '(-r --auto-restart)'{-r,--auto-restart}'[processes to auto restart on death]:processes:_overmind_process_list_with_all'
  '(-b --colors)'{-b,--colors}'[xterm color codes for process names]:colors:_overmind_colors'
  '(-T --show-timestamps)'{-T,--show-timestamps}'[add timestamps to the output]'
  '(-m --formation)'{-m,--formation}'[number of each process type to run]:formation:_overmind_formation_list'
  '--formation-port-step[step to increase port number for the next process instance]:port step:'
  '(-i --stop-signals)'{-i,--stop-signals}'[signals sent to processes during shutdown]:stop signals:_overmind_stop_signal_list'
  '(-D --daemonize)'{-D,--daemonize}'[launch Overmind as a daemon]'
  '(-F --tmux-config)'{-F,--tmux-config}'[alternative tmux config path]:tmux config:_files'
  '(-x --ignored-processes)'{-x,--ignored-processes}'[process names to prevent from launching]:processes:_overmind_process_list'
  '(-H --shell)'{-H,--shell}'[shell to run processes with]:shell:_overmind_shells'
)

_overmind_run_command() {
  if (( CURRENT == 3 )); then
    _command_names -e
  else
    _normal
  fi
}

_overmind() {
  local context state state_descr line command canonical ret=1
  typeset -A opt_args

  _arguments -C \
    '(-h --help)'{-h,--help}'[show help]' \
    '(-v --version)'{-v,--version}'[print the version]' \
    '1:command:->command' \
    '*::arg:->args' && ret=0

  case "$state" in
    command)
      _describe -t commands 'overmind command' _overmind_commands && ret=0
      ;;
    args)
      command="${words[2]}"
      canonical="$(_overmind_canonical_command "$command")"

      case "$canonical" in
        start)
          _arguments -C \
            "${_overmind_common_options[@]}" \
            "${_overmind_start_options[@]}" \
            '*:: :->start_args' && ret=0
          ;;
        restart | stop)
          _arguments -C \
            "${_overmind_common_options[@]}" \
            '*:process:_overmind_processes' && ret=0
          ;;
        connect)
          _arguments -C \
            '(-c --control-mode)'{-c,--control-mode}'[connect to tmux session in control mode]' \
            "${_overmind_common_options[@]}" \
            '1:process:_overmind_processes' && ret=0
          ;;
        quit | kill | echo | status)
          _arguments -C \
            "${_overmind_common_options[@]}" && ret=0
          ;;
        run)
          _overmind_run_command && ret=0
          ;;
      esac
      ;;
  esac

  case "$state" in
    network)
      _describe -t networks 'network' _overmind_networks && ret=0
      ;;
    start_args)
      _message 'No positional arguments for overmind start' && ret=0
      ;;
  esac

  return "$ret"
}

if (( $+functions[compdef] )); then
  compdef _overmind overmind
fi
