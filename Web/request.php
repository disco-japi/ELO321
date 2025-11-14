<?php if ($tab == 6) {
  if (array_key_exists("send", $_POST) && $_POST["send"] == "true") {
    $info = "";
    $break = false;
    if (count($_POST) > 0) {
      $titulo = $_POST["titulo"];
      $desc = $_POST["desc"];
      $esp = $_POST["esp"];
      $rut = $_SESSION["rut"];
      if ($_POST["tipo"] == "err") {
        $sql = "call registrar_error('$titulo','$desc','$rut',$esp,1)";
      } else if ($_POST["tipo"] == "fun") {
        $amb = $_POST["ambs"];
        $cr1 = $_POST["criterio1"];
        $cr2 = $_POST["criterio2"];
        $cr3 = $_POST["criterio3"];
        $sql = "call registrar_funcionalidad('$titulo','$desc','$rut',$amb,$esp,1,'$cr1','$cr2','$cr3')";
      } else {
        $info = "Solicitud inválida";
        $break = true;
      }
      if ($break == false) {
        $call = $conn->query($sql);
        if ($call != false) {
          $info = "Solicitud ingresada exitosamente";
        } else {
          $info = "Error: $conn->error";
        }
      }
    } else {
      $info = "Solicitud inválida";
    }

?>

    <body>
      <div class="container">
        <center>
          <div class="alert alert-primary" role="alert">
            <?php echo $info; ?>
          </div>
        </center>
      </div>
    </body>
  <?php } ?>
  <script type="text/javascript">
    function checkradio() {
      if (document.getElementById('fun').checked) {
        document.getElementById("amb").style.display = '';
      } else {
        document.getElementById("amb").style.display = 'none';
      }
    }

    function validate() {
      let field = [];
      if (document.getElementById("desc").value == "") {
        field.push(" Descripción");
      }
      if (field.length != 0) {
        document.getElementById("error").innerHTML = "Error: Campo(s) sin completar: " + field + "\b.";
        return false;
      } else {
        return true;
      }
    }
  </script>
  <h1>Nueva Solicitud</h1>
  <form class="p-4 p-md-5 border rounded-3 bg-body-tertiary" style="max-width:50%;" action="dashboard.php?tab=6" method="POST" onsubmit="return validate();">
    Tipo de solicitud:<br>
    <input type="hidden" name="send" value="true" />
    <input type="radio" class="form-check-input" id="err" name="tipo" value="err" checked="true" oninput="checkradio()">
    <label for="err">Error</label><br>
    <input type="radio" class="form-check-input" id="fun" name="tipo" value="fun" oninput="checkradio()">
    <label for="fun">Funcionalidad</label><br><br>
    <div class="form-floating mb-3"><input class="form-control" required type="text" minlength="20" maxlength="100" class="form-control" label="titulo" name="titulo" id="titulo" placeholder="Título de la solicitud" /><label for="titulo">Título</label></div>
    <div class="form-floating mb-3"><textarea label="desc" required class="form-control" name="desc" id="desc" placeholder="Descripción" minlength="20" maxlength="200" rows="4" cols="50"></textarea><label class="form-label" for="desc">Descripción</label></div>
    <div id="esp">
      <label for="esp" class="form-label">Especialidad relacionada</label><br>
      <select class="form-select mb-3" name="esp">
        <option value="1">Backend</option>
        <option value="2">Seguridad</option>
        <option value="3">UX/UI</option>
      </select>
    </div>
    <div id="amb">
      <label class="form-label" for="ambs">Selecciona un ambiente de desarrollo</label><br>
      <select label="ambs" class="form-select" name="ambs">
        <option value="1">Web</option>
        <option value="2">Movil</option>
      </select><br>
      <div class="form-floating mb-3"><input class="form-control" maxlength="150" type="text" label="criterio1" name="criterio1" id="criterio1" placeholder="Criterio 1"><label for="criterio1">Criterio 1</label></div>
      <div class="form-floating mb-3"><input class="form-control" maxlength="150" type="text" label="criterio2" name="criterio2" id="criterio2" placeholder="Criterio 2"><label for="criterio2">Criterio 2</label></div>
      <div class="form-floating mb-3"><input class="form-control" maxlength="150" type="text" label="criterio3" name="criterio3" id="criterio3" placeholder="Criterio 3"><label for="criterio3">Criterio 3</label></div>
    </div>
    <hr class="my-4" />
    <button type="submit" class="btn btn-primary px-4">Enviar solicitud <i class="bi bi-send"></i></button>
    <p id=error style="color:red;"></p>
  </form>
  <script>
    checkradio()
  </script>
<?php } ?>