import gleam/erlang/process.{type Subject}
import gleam/io

type Message {
  Add(Int)
  Subtract(Int)
  GetTotal
}

type MessageQueue =
  Subject(Message)

type ResultChannel =
  Subject(Int)

fn counter(caller: Subject(MessageQueue), result_channel: ResultChannel) -> Nil {
  // Send message queue to calling process
  let msg_queue = process.new_subject()
  process.send(caller, msg_queue)
  // Handle calls
  handler(0, msg_queue, result_channel)
}

// Handle calls
fn handler(
  count: Int,
  msg_queue: MessageQueue,
  result_channel: ResultChannel,
) -> Nil {
  case process.receive(msg_queue, 1000) {
    Ok(Add(n)) -> {
      handler(count + n, msg_queue, result_channel)
    }
    Ok(Subtract(n)) -> {
      handler(count - n, msg_queue, result_channel)
    }
    Ok(GetTotal) -> {
      process.send(result_channel, count)
      handler(count, msg_queue, result_channel)
    }
    Error(_) -> panic as "Don't know what to do!"
  }
}

fn send_messages(
  counter_channel: MessageQueue,
  result_channel: ResultChannel,
  n: Int,
  message: Message,
) -> Nil {
  case n {
    0 -> Nil
    _ -> {
      process.send(counter_channel, message)
      send_messages(counter_channel, result_channel, n - 1, message)
    }
  }
}

// Get result and print it
fn print_counter(
  counter_channel: MessageQueue,
  result_channel: ResultChannel,
) -> Int {
  process.send(counter_channel, GetTotal)
  let assert Ok(res) = process.receive(result_channel, 2000)
  io.debug(res)
}

fn send_and_print(
  counter_channel: MessageQueue,
  result_channel: ResultChannel,
  message: Message,
) -> Int {
  send_messages(counter_channel, result_channel, 1_000_000, message)
  print_counter(counter_channel, result_channel)
}

pub fn main() -> Int {
  // Start counter process
  let channel = process.new_subject()
  let result_channel = process.new_subject()
  let counter = fn() { counter(channel, result_channel) }
  process.start(counter, True)

  // counter process sends us its message channel
  let assert Ok(counter_channel) = process.receive(channel, 1000)

  send_and_print(counter_channel, result_channel, Add(1))
  send_and_print(counter_channel, result_channel, Subtract(1))
}
