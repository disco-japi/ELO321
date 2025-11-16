<?php //Log in
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

mysqli_report(MYSQLI_REPORT_ERROR);
$servername = "db";
$username = "web";
$password = "1234";
$login = false;
$err = "";
$nombre = "";
$conn = new mysqli($servername, $username, $password, "telefactory");
$tab = 0;
$nombre = "";
$administrador = false;
if ($conn->connect_error) {
  $err = ("Error de conexión a base de datos: " . $conn->connect_error);
} else if ($_SERVER['PHP_SELF'] != '/login.php' && $_SERVER['PHP_SELF'] != '/register.php' && $_SERVER['PHP_SELF'] != '/procregister.php') {
  session_start();
  if (count($_SESSION) == 0 && count($_POST) != 0) {
    $nombre_usuario = $_POST["username"];
    $passwd = $_POST['passwd'];
    $sql = "select validador_login('$nombre_usuario','$passwd') as resultado";
    $result = $conn->query($sql);
    $check = $result->fetch_assoc();
    if ($check["resultado"] == 'Administrador' || $check["resultado"] == 'Usuario') {
      $get = $conn->query("select * from Persona where nombre_usuario = '$nombre_usuario'")->fetch_assoc();
      $_SESSION['nombre'] = $get['nombre'];
      $_SESSION['rut'] = $get['rut'];
      $_SESSION['nombre_usuario'] = $nombre_usuario;
      if ($check["resultado"] == 'Administrador') {
        $_SESSION['administrador'] = true;
      } else if ($check["resultado"] == 'Usuario') {
        $_SESSION['administrador'] = false;
      }
    } else {
      $err = "Nombre de usuario o contraseña incorrectos.";
    }
  }
  if (count($_SESSION) != 0) {
    $administrador = $_SESSION['administrador'];
    $nombre_usuario = $_SESSION['nombre_usuario'];
    $nombre = $_SESSION['nombre'];
    $rut = $_SESSION['rut'];
    if ($conn->query("select nombre from Persona where nombre_usuario = '$nombre_usuario'")->fetch_assoc()['nombre'] != "") {
      $login = true;
    } else {
      $err = "Error desconocido, por favor, inicie sesión de nuevo.";
      session_unset();
      session_destroy();
    }
  }
}
function checktab($Ltab, $tab)
{
  if ($Ltab == $tab && $_SERVER['PHP_SELF'] == '/index.php') {
    echo "secondary";
  } else {
    echo "white";
  }
}
if (array_key_exists('tab', $_GET)) $tab = $_GET["tab"]; ?>
<!DOCTYPE html>
<html lang="es">

<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>TeleFactory</title>
  <link
    href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/css/bootstrap.min.css"
    rel="stylesheet"
    integrity="sha384-sRIl4kxILFvY47J16cr9ZwB07vP4J8+LH7qKQnuqkuIAvNWLzeN8tE5YBujZqJLB"
    crossorigin="anonymous" />
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.13.1/font/bootstrap-icons.min.css">
  <style>
    html,
    body {
      height: 80%
    }
  </style>

  <header id="header" class="p-3 text-bg-dark" <?php if ($_SERVER['PHP_SELF'] == '/info.php' || $_SERVER['PHP_SELF'] == '/edit.php') echo "style='display:none;'" ?>>
    <div class="container d-flex flex-wrap align-items-center justify-content-center justify-content-lg-start">
      <a href="/index.php" class="nav-link px-2 text-white">
        <h1><i class="bi bi-motherboard-fill"></i> TeleFactory</h1>
      </a>
      <ul
        class="nav col-12 col-lg-auto me-lg-auto mb-2 justify-content-center mb-md-0">
        <li><a href="index.php?tab=3" class="nav-link px-2 text-<?php checktab(3, $tab) ?>">Todo <i class="bi bi-house"></i></a></li>
        <?php if ($login) { ?>
          <?php if ($administrador) { ?>
            <li><a href="/index.php?tab=1" class="nav-link px-2 text-<?php checktab(1, $tab) ?>">Ventas <i class="bi bi-wrench"></i></a></li>
          <?php } else { ?>
            <li><a href="/index.php?tab=2" class="nav-link px-2 text-<?php checktab(2, $tab) ?>">Mis compras <i class="bi bi-person"></i></a></li>
        <?php }
        } ?>
      </ul>
      <form class="col-12 col-lg-auto mb-0 mb-lg-0 me-lg-3" role="search" action="index.php" method="GET">
        <input type="hidden" name="tab" value="4" />
        <div class="input-group mb-0">
          <input
            type="search"
            minlength="3"
            required
            class="form-control form-control-dark"
            placeholder="Buscar..."
            aria-label="Search"
            name="search" />
          <button class="btn btn-outline-light" type="submit"><i class="bi bi-search"></i></button>
        </div>
      </form>
      <div class="text-end">
        <?php
        if ($login) { ?>
          <div class="dropdown">
            <button class="btn btn-<?php echo ($administrador ? "warning" : "primary"); ?> dropdown-toggle" type="button" id="dropdownMenuButton1" data-bs-toggle="dropdown" aria-expanded="false">
              <?php echo $nombre; ?>
            </button>
            <ul class="dropdown-menu" aria-labelledby="dropdownMenuButton1">
              <li>
                <h6 class="dropdown-header"><?php echo $nombre_usuario; ?></h6>
              </li>
              <li>
                <h6 class="dropdown-header"><?php echo "RUT: $rut"; ?></h6>
              </li>
              <li>
                <h6 class="dropdown-header"><?php echo ($administrador ? "Administrador" : "Usuario"); ?></h6>
              </li>
              <li><a class="dropdown-item" href="login.php">Cerrar sesión</a></li>
            </ul>
          </div>
        <?php } else { ?>
          <button type="button" class="btn btn-light me-2" onclick="location.href='login.php'">Iniciar sesión</button>
          <button type="button" class="btn btn-primary" onclick="location.href='register.php'">Registrarse</button>
        <?php } ?>
      </div>
    </div>
  </header>
</head>

<body>
  <?php
  if ($err != "") { ?>
    <div class="container py-5">
      <center>
        <div class="alert alert-danger" role="alert">
          <?php echo $err; ?>
        </div>
      </center>
    </div>
  <?php } ?>
  <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.2.0/dist/js/bootstrap.bundle.min.js" integrity="sha384-A3rJD856KowSb7dwlZdYEkO39Gagi7vIsF0jrRAoQmDKKtQBHUuLZ9AsSv4jD4Xa" crossorigin="anonymous"></script>
</body>