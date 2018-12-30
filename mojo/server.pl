use Mojolicious::Lite;

get '/' => sub {
  my $self = shift;
  $self->render(text => 'Hello, world!!!');
};

get '/form' => sub {
  my $self = shift;
  my $is_logout = $self->param('logout');
  my $username;

  if ($is_logout) {
    delete $self->session->{'username'};
  } else {
    $username = $self->session('username');
  }

  if (defined $username) {
    $self->render('greetings', username => $username);
  } else {
    $self->render('form');
  }
};

post '/greetings' => sub {
  my $self = shift;
  my $username = $self->param('username');

  $self->session('username' => $username);
  $self->render('greetings', username => $username);
};

app->start;
