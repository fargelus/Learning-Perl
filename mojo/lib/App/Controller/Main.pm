package App::Controller::Main;


use Mojo::Base 'Mojolicious::Controller';
use App::Model::Users;
use App::Helpers;
use Package::Alias
    RU_LEXER => 'App::Locale::Ru',
    EN_LEXER => 'App::Locale::En';


sub index {
  my $self = shift;

  if ( $self->session('id') ) {
    $self->redirect_to('greetings');
  }

  stashLexer($self);
  $self->render;
}

sub greetings {
  my $self = shift;
  my $id = $self->session('id');
  # Кэшируем запросы к базе
  state $fetch_rec = App::Model::Users->select($id);

  my $is_update = $self->flash('update');
  if (@$fetch_rec[0] ne $id || $is_update) {
    $self->flash('update' => 0);
    $fetch_rec = App::Model::Users->select($id);
  }

  stashLexer($self);
  # avatar_src: undef или путь к аве на сервере
  $self->render(
    username => @$fetch_rec[1],
    avatar_src => @$fetch_rec[3],
  );
}

sub translate {
  my $self = shift;

  my $lang = $self->param('lang');
  my $referrer = $self->req->content->headers->referrer;
  my $url = getTranslatedPageURL($lang, $referrer);
  $self->redirect_to($url);
}


1;
