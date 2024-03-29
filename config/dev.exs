import Config

config :brod,
  clients: [
    kafka_client: [
      endpoints: [localhost: 29092]
    ]
  ]
