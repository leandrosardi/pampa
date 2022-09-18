require 'pampa'
# TODO: require the config.rb here

l = BlackStack::Pampa.logger

l.log 'Workers Status Report:'

BlackStack::Pampa.nodes { |n|
  l.logs "node: #{n.name}... "
  begin
    l.logs 'Connecting... '
    n.connect
    l.done

    n.workers.each { |w|
      l.logs "Worker #{w.id}... "
      begin
        l.logs 'Last log update: ' 
        l.logf "#{w.log_minutes_ago.to_s} mins. ago"

        l.logs 'Tasks in queue: '
        l.logf w.pending_tasks(:search_odd_numbers).to_s

      l.done
      rescue => e
        l.error e
      end
    }

    l.logs 'Disconnect... '
    n.disconnect
    l.done

  l.done
  rescue => e
    l.error e
  end
}
