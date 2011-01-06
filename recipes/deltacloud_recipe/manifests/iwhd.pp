# Deltacloud iwhd puppet definitions

class deltacloud::iwhd inherits deltacloud {
  ### Install the deltacloud components
    package { 'iwhd':
               provider => 'yum', ensure => 'installed' }

  ### Start the deltacloud services
    file { "/data":    ensure => 'directory' }
    file { "/data/db": ensure => 'directory' }
    service { 'mongod':
      ensure  => 'running',
      enable  => true,
      require => [Package['iwhd'], File["/data/db"]]}
    service { 'iwhd':
      ensure  => 'running',
      enable  => true,
      hasstatus => true,
      require => [Package['iwhd'],
                  Service[mongod]]}

    # XXX ugly hack but iwhd might take some time to come up
    exec{"iwhd_startup_pause":
                command => "/bin/sleep 2",
                unless  => '/usr/bin/curl http://localhost:9090',
                require => Service[iwhd]}
}

class deltacloud::iwhd::disabled {
  ### Stop the deltacloud services
    service { 'mongod':
      ensure  => 'stopped',
      enable  => false,
      require => Service[iwhd]}
    service { 'iwhd':
      ensure  => 'stopped',
      enable  => false,
      hasstatus => true}


  ### Uninstall the deltacloud components
    package { 'iwhd':
                provider => 'yum', ensure => 'absent',
                require  => [Package['deltacloud-aggregator'], Service['iwhd']]}
}

# Create a named bucket in iwhd
define deltacloud::create_bucket(){
  package{'curl': ensure => 'installed'}
  exec{"create-bucket-${name}":
         command => "/usr/bin/curl -X PUT http://localhost:9090/templates",
         require => [Exec['iwhd_startup_pause'], Package[curl]] }
}