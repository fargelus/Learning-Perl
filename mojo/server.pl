use Mojolicious::Lite;
use DBI;
use Mojo::Message::Response;
use Data::Dumper;
use Cwd;

my $dbh = DBI->connect('dbi:SQLite:database.db', '', '') or die 'Could not connect';

helper db => sub { $dbh };

helper create_table => sub {
  my $self = shift;
  warn "Creating table 'users'\n";
  $self->db->do('CREATE TABLE users (id INTEGER PRIMARY KEY, name varchar(255), pwd varchar(255))');
};

helper select_all => sub {
  my $self = shift;
  my $db = eval {$self->db->prepare("SELECT * FROM users")} || return undef;

  $db->execute();
  $db->fetchall_arrayref();
};

helper select => sub {
  my $self = shift;
  my ($looking_name, $looking_pwd) = @_;
  my $query = "SELECT name, pwd FROM users WHERE name='$looking_name' AND pwd='$looking_pwd'";
  my $db = eval {$self->db->prepare($query)} || return undef;

  $db->execute();
  $db->fetchrow_arrayref();
};

helper insert => sub {
  my $self = shift;
  my ($name, $pwd) = @_;
  my $query = 'INSERT INTO USERS (name, pwd) VALUES(?, ?)';
  my $db = eval {$self->db->prepare($query)} || return undef;

  $db->execute($name, $pwd);
  1;
};

app->select_all() || app->create_table();

get '/' => sub {
  my $self = shift;

  my $username = $self->session('username');
  if ($username) {
    $self->render('greetings', username => $username);
  } else {
    $self->render('index');
  }
};

get '/login' => sub {
  my $self = shift;
  $self->render('login');
};

post '/login' => sub {
  my $self = shift;
  my ($username, $pwd) = (
    $self->param('username'),
    $self->param('password')
  );

  my $target_rec = $self->select($username, $pwd);
  if ($target_rec) {
    $self->session('username' => $username);
    $self->render('greetings', username => $username);
  } else {
    $self->render(text => "Пользователя $username не существует в базе");
  }
};

get '/reg' => sub {
  my $self = shift;
  $self->render('registration');
};

post '/reg' => sub {
  my $self = shift;
  my $username = $self->param('username');
  my $pwd = $self->param('password');

  my $insert = $self->insert($username, $pwd);
  if ($insert) {
    $self->session('username' => $username);
    $self->render('greetings', username => $username);
  } else {
    $self->render(text => "Не удалось зарегистрировать пользователя $username");
  }
};

post '/update' => sub {
  my $self = shift;

  my $avatarFile = $self->req->upload('avatar');
  if ($avatarFile) {
    my $filename = $avatarFile->filename;
    my $dir = getcwd();
    my $path = $dir."/public/store/$filename";
    $avatarFile->move_to($path);
  }
  # my $res = Mojo::Message::Response->new();
  # $self->res->headers->header('X-Bender' => 'Bite my shiny metal ass!');
};

get '/logout' => sub {
  my $self = shift;
  delete $self->session->{'username'};
  $self->render('index');
};

app->start;
