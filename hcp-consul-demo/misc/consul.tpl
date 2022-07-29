global:
  name: consul
  image: 'hashicorp/consul-enterprise:${consul_version}-ent'
  enabled: true
  datacenter: ${datacenter}
  acls:
    manageSystemACLs: true
  gossipEncryption:
      autoGenerate: true
  enableConsulNamespaces: true
  enterpriseLicense:
    secretName: ${consul_license_secret}
    secretKey: 'key'
server:
  replicas: 3
  exposeGossipAndRPCPorts: true
  ports:
    serflan:
      port: 7301
client:
  enabled: true
  exposeGossipPorts: true
  grpc: true
connectInject:
  enabled: true
controller:
  enabled: true
ingressGateways:
  enabled: true
  gateways:
    - name: ingress-gateway
      service:
        type: LoadBalancer
ui:
  enabled: true
  service:
    type: LoadBalancer
    ports:
    - port: 80
