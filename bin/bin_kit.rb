require "pathname"
require "fileutils"
require "open3"

def capture!(*args)
  log "Executing #{args} and capturing results"
  out,err,status = Open3.capture3(*args)
  if status.success?
    return [out,err]
  else
    $STDERR.puts out
    $STDERR.puts err
    log "#{args} failed"
    abort
  end
end
# We don't want the setup method to have to do all this error
# checking, and we also want to explicitly log what we are
# executing. Thus, we use this method instead of Kernel#system
def system!(*args)
  if ENV["BRUT_BIN_KIT_DEBUG"] == "true"
    log "Executing #{args}"
    out,err,status = Open3.capture3(*args)
    if status.success?
      log "#{args} succeeded"
    else
      log "#{args} failed"
      log "STDOUT:"
      $stdout.puts out
      log "STDERR:"
      $stderr.puts err
      abort
    end
  else
    log "Executing #{args}"
    if system(*args)
      log "#{args} succeeded"
    else
      log "#{args} failed"
      abort
    end
  end
end

# It's helpful to know what messages came from this
# script, so we'll use log instead of `puts`
def log(message)
  puts "[ #{$0} ] #{message}"
end

ROOT_DIR = ((Pathname(__dir__) / ".." ).expand_path)
