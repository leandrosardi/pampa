require 'pampa'

DELAY = 10 # seconds
ONCE = false # if false, execute this process every DELAY seconds

BlackStack::Pampa.run_stand_alone({
    :log_filename => 'example.log',
    :delay => DELAY,
    :run_once => ONCE,
    :function => Proc.new do |l, *args|
        begin
            l.log 'Hello, World!'

            l.log "1. Executing this process recursively, with a timeframe of #{DELAY} seconds between the starting of each one."
            l.log "2. If an execution takes more than #{DELAY} seconds, the next execution will start immediatelly."
            l.log "3. If an error occurs, the process will stop. So be sure to catch all exceptions here."

            # your code here

        rescue => e
            l.logf "Error: #{e.to_console.red}"
        # CTRL+C will be catched here
        rescue Interrupt => e
            l.logf "Interrupted".red
            exit(0)
        ensure
            l.log "End of the process."
        end
    end, 
})