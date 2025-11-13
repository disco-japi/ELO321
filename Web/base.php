<?php //Log in
error_reporting(E_ALL);
ini_set('display_errors', 1);
mysqli_report(MYSQLI_REPORT_ERROR);
$servername = "localhost";
$username = "web";
$password = "1234";
$login = false;
$err = "";
$nombre = "";
$conn = new mysqli($servername, $username, $password, "basesita");
$tab = 0;
$nombre = "";
if ($conn->connect_error) {
  $err = ("Error de conexión a base de datos: " . $conn->connect_error);
} else if ($_SERVER['PHP_SELF'] != '/login.php' && $_SERVER['PHP_SELF'] != '/register.php' && $_SERVER['PHP_SELF'] != '/procregister.php') {
  session_start();
  if (count($_SESSION) == 0 && count($_POST) != 0) {
    $nombre_usuario = $_POST["username"];
    $passwd = $_POST['passwd'];
    $rol = $_POST['rol'];
    $sql = "select validador_login('$nombre_usuario','$passwd') as resultado";
    $result = $conn->query($sql);
    $check = $result->fetch_assoc();
    if ($check["resultado"] == $rol) {
      $get = $conn->query("select * from Persona where nombre_usuario = '$nombre_usuario'")->fetch_assoc();
      $_SESSION['nombre'] = $get['nombre'];
      $_SESSION['rut'] = $get['rut'];
      $_SESSION['nombre_usuario'] = $nombre_usuario;
      if (array_key_exists('rol', $_POST)) {
        if ($_POST['rol'] == 'Ingeniero') {
          $_SESSION['ingeniero'] = true;
        } else {
          $_SESSION['ingeniero'] = false;
        }
      }
    } else {
      $err = "Nombre de usuario, contraseña o rol incorrectos.";
    }
  } else if (count($_SESSION) == 0 && count($_POST) == 0) {
    $err = "Sesión inválida, por favor, inicie sesión.";
  }
  if (count($_SESSION) != 0) {
    $ingeniero = $_SESSION['ingeniero'];
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
  if ($Ltab == $tab) {
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
    <div
      class="d-flex flex-wrap align-items-center justify-content-center justify-content-lg-start">
      <h1><i class="bi bi-motherboard-fill"></i> TeleFactory</h1>
      <ul
        class="nav col-12 col-lg-auto me-lg-auto mb-2 justify-content-center mb-md-0">
        <li><a href="dashboard.php?tab=0" class="nav-link px-2 text-<?php checktab(0, $tab) ?>">Principal <i class="bi bi-house"></i></a></li>
        <?php if ($login) { ?>
          <?php if ($ingeniero) { ?>
            <li><a href="<?php echo htmlspecialchars($_SERVER["PHP_SELF"]); ?>?tab=1" class="nav-link px-2 text-<?php checktab(1, $tab) ?>">Solicitudes de funcionalidad <i class="bi bi-wrench"></i></a></li>
            <li><a href="<?php echo htmlspecialchars($_SERVER["PHP_SELF"]); ?>?tab=2" class="nav-link px-2 text-<?php checktab(2, $tab) ?>">Solicitudes de gestión de error <i class="bi bi-bug"></i></a></li>
            <li><a href="<?php echo htmlspecialchars($_SERVER["PHP_SELF"]); ?>?tab=3" class="nav-link px-2 text-<?php checktab(3, $tab) ?>">Solicitudes asignadas a mi <i class="bi bi-person"></i></a></li>
          <?php } else { ?>
            <li><a href="<?php echo htmlspecialchars($_SERVER["PHP_SELF"]); ?>?tab=5" class="nav-link px-2 text-<?php checktab(5, $tab) ?>">Mis compras <i class="bi bi-person">/a></li>
          <?php } ?>
      </ul>
      <form class="col-12 col-lg-auto mb-0 mb-lg-0 me-lg-3" role="search" action="dashboard.php" method="GET">
        <input type="hidden" name="tab" value="7" />
        <div class="input-group mb-0">
          <input
            type="search"
            minlength="3"
            required
            class="form-control form-control-dark"
            placeholder="Buscar..."
            aria-label="Search"
            name="search" />
          <button class="btn btn-outline-light" type="button" data-bs-toggle="modal" data-bs-target="#advSearch"><i class="bi bi-plus-lg"></i></button> <!-- Busqueda avanzada -->
          <button class="btn btn-outline-light" type="submit"><i class="bi bi-search"></i></button>
        </div>
      </form>
      <div class="modal fade" id="advSearch" tabindex="-1" aria-labelledby="advSearchLabel" aria-hidden="true">
        <div class="modal-dialog">
          <div class="modal-content">
            <div class="modal-header">
              <h1 class="modal-title fs-5" id="advSearchLabel">Búsqueda Avanzada</h1>
              <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <form class="border rounded-3 bg-body-tertiary" action="dashboard.php" method="GET">
              <div class="modal-body">
                <input type="hidden" name="tab" value="8" />
                <div class="form-floating mb-3"><input class="form-control" type="text" minlength="3" maxlength="100" name="titulo" id="titulo" placeholder="Título de la solicitud" /><label for="titulo">Título de la solicitud</label></div>
                <label for="reciente">Solicitudes mas recientes de</label>
                <input
                  class="form-control"
                  type="date"
                  id="reciente"
                  name="reciente"
                  value="2015-07-22"
                  min="2000-01-01"
                  max="2050-12-31" /><br>
                <div id="esp">
                  <label for="esp">Selecciona una especialidad</label><br>
                  <select class="form-select" name="esp">
                    <option value="">No especifica</option>
                    <option value="Backend">Backend</option>
                    <option value="Seguridad">Seguridad</option>
                    <option value="UX/UI">UX/UI</option>
                  </select>
                </div><br>
                <div id="ambs">
                  <label for="ambs">Ambiente (solo funcionalidad)</label><br>
                  <select class="form-select" name="ambs">
                    <option value="">No especifica</option>
                    <option value="Web">Web</option>
                    <option value="Movil">Movil</option>
                  </select>
                </div><br>
                <div id="estado">
                  <label for="estado">Estado de la solicitud</label><br>
                  <select class="form-select" name="estado">
                    <option value="">No especifica</option>
                    <option value="">En tramite</option>
                    <option value="">Movil</option>
                  </select>
                </div><br>
              </div>
              <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cerrar</button>
                <button type="submit" class="btn btn-primary">Buscar <i class="bi bi-search"></i></button>
              </div>
            </form>
          </div>
        </div>
      </div>
    <?php } else echo "</ul>"; ?>
    <div class="text-end">
      <?php
      if ($login) { ?>
        <div class="dropdown">
          <button class="btn btn-<?php echo ($ingeniero ? "warning" : "primary"); ?> dropdown-toggle" type="button" id="dropdownMenuButton1" data-bs-toggle="dropdown" aria-expanded="false">
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
              <h6 class="dropdown-header"><?php echo ($ingeniero ? "Ingeniero" : "Usuario"); ?></h6>
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