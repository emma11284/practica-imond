const datos = {
    ventas: [],
    tickets: [],
    usuarios: [],
    nps: [],
    canales: [],
    provincias: [],
    ventasProducto: [],
    productos: []
};

const opcionesMonto = {
    ventas_con_iva_y_envio: "Con IVA y envío",
    ventas_con_iva_sin_envio: "Con IVA, sin envío",
    ventas_sin_iva_ni_envio: "Sin IVA ni envío"
};

const colores = {
    oscuro: "#103d2b",
    salvia: "#8cb19d",
    oliva: "#899960",
    grilla: "#e4ebe6",
    texto: "#52685b",
    detractores: "#a5483b",
    pasivos: "#b78927",
    promotores: "#24704d"
};

function elemento(id) {
    return document.getElementById(id);
}

function escribir(id, texto) {
    elemento(id).textContent = texto;
}

function numero(valor) {
    if (
        valor === undefined ||
        valor === null ||
        String(valor).trim() === ""
    ) {
        throw new Error("Falta un valor numérico.");
    }

    const resultado = Number(valor);

    if (!Number.isFinite(resultado)) {
        throw new Error("Se encontró un número inválido.");
    }

    return resultado;
}

function formato(valor, decimales = 0) {
    return valor.toLocaleString("es-AR", {
        minimumFractionDigits: decimales,
        maximumFractionDigits: decimales
    });
}

function escapar(texto) {
    return String(texto).replace(/[&<>"']/g, caracter => ({
        "&": "&amp;",
        "<": "&lt;",
        ">": "&gt;",
        '"': "&quot;",
        "'": "&#39;"
    }[caracter]));
}

// Lectura de CSV, incluyendo campos entre comillas.
function interpretarCSV(texto) {
    texto = texto.replace(/^\uFEFF/, "");

    const filas = [];
    let fila = [];
    let campo = "";
    let entreComillas = false;

    for (let i = 0; i < texto.length; i++) {
        const caracter = texto[i];

        if (caracter === '"') {
            if (entreComillas && texto[i + 1] === '"') {
                campo += '"';
                i++;
            } else {
                entreComillas = !entreComillas;
            }
        } else if (caracter === "," && !entreComillas) {
            fila.push(campo);
            campo = "";
        } else if (
            (caracter === "\n" || caracter === "\r") &&
            !entreComillas
        ) {
            if (caracter === "\r" && texto[i + 1] === "\n") i++;

            fila.push(campo);

            if (fila.some(valor => valor !== "")) filas.push(fila);

            fila = [];
            campo = "";
        } else {
            campo += caracter;
        }
    }

    if (entreComillas) {
        throw new Error("El CSV contiene comillas sin cerrar.");
    }

    if (campo !== "" || fila.length > 0) {
        fila.push(campo);
        filas.push(fila);
    }

    if (filas.length === 0) {
        throw new Error("El CSV está vacío.");
    }

    const encabezados = filas.shift();

    return filas.map(valores => {
        if (valores.length !== encabezados.length) {
            throw new Error("El CSV contiene una fila incompleta.");
        }

        return Object.fromEntries(
            encabezados.map((nombre, i) => [nombre, valores[i]])
        );
    });
}

async function leerCSV(nombre) {
    const respuesta = await fetch("../dw/" + nombre);

    if (!respuesta.ok) {
        throw new Error("No se pudo leer " + nombre);
    }

    return interpretarCSV(await respuesta.text());
}

function elegirUnaFila(filas, condicion) {
    const coincidencias = filas.filter(condicion);

    if (coincidencias.length > 1) {
        throw new Error("Hay varios resultados para la misma selección.");
    }

    return coincidencias[0] ?? null;
}

function agregarOpcion(id, valor, etiqueta) {
    const opcion = document.createElement("option");
    opcion.value = valor;
    opcion.textContent = etiqueta;
    elemento(id).appendChild(opcion);
}

function nombreMes(mes) {
    const [anio, numeroMes] = mes.split("-");
    const fecha = new Date(Number(anio), Number(numeroMes) - 1, 1);

    return fecha.toLocaleDateString("es-AR", {
        month: "long",
        year: "numeric"
    });
}

function mesCorto(mes) {
    const [anio, numeroMes] = mes.split("-");
    const fecha = new Date(Number(anio), Number(numeroMes) - 1, 1);

    return fecha.toLocaleDateString("es-AR", {
        month: "short"
    }).replace(".", "") + " " + anio.slice(2);
}

function cargarSelectores() {
    const meses = [...new Set(
        datos.usuarios
            .map(fila => fila.periodo)
            .filter(periodo => periodo !== "Todo el período")
    )].sort();

    for (const mes of meses) {
        agregarOpcion("filtro-periodo", mes, nombreMes(mes));
    }

    for (const canal of datos.canales) {
        agregarOpcion("filtro-canal", canal.channel_key, canal.name);
    }

    for (const provincia of datos.provincias) {
        agregarOpcion(
            "filtro-provincia",
            provincia.province_key,
            provincia.name
        );
    }

    for (const producto of datos.productos) {
        agregarOpcion(
            "filtro-producto",
            producto.product_key,
            producto.name
        );
    }
}

function coincideFecha(fila, periodo) {
    return periodo === "Todo el período" ||
        fila.date_key.slice(0, 6) === periodo.replace("-", "");
}

// Agrupa y suma importes aditivos preparados en SQL.
function agruparImportes(filas, obtenerClave, columna) {
    const totales = new Map();

    for (const fila of filas) {
        const clave = obtenerClave(fila);
        const centavos = Math.round(numero(fila[columna]) * 100);

        totales.set(clave, (totales.get(clave) ?? 0) + centavos);
    }

    return [...totales.entries()]
        .map(([clave, centavos]) => [clave, centavos / 100]);
}

function actualizarDashboard() {
    try {
        const periodo = elemento("filtro-periodo").value;
        const canal = elemento("filtro-canal").value;
        const provincia = elemento("filtro-provincia").value;
        const producto = elemento("filtro-producto").value;
        const columnaMonto = elemento("filtro-monto").value;

        const descripcionMonto = opcionesMonto[columnaMonto];

        if (!descripcionMonto) {
            throw new Error("Tipo de importe inválido.");
        }

        const todosCanales = canal === "Todos los canales";
        const todasProvincias = provincia === "Todas las provincias";

        const canalNombre = todosCanales
            ? "Todos los canales"
            : datos.canales.find(fila => fila.channel_key === canal)?.name;

        const provinciaNombre = todasProvincias
            ? "Todas las provincias"
            : datos.provincias.find(
                fila => fila.province_key === provincia
            )?.name;

        if (!canalNombre || !provinciaNombre) {
            throw new Error("No se reconoce el canal o la provincia.");
        }

        escribir(
            "detalle-ventas",
            "Pedidos pagados o completados. " + descripcionMonto + "."
        );

        escribir(
            "detalle-ventas-mensuales",
            "Pedidos válidos · " + descripcionMonto + " · Millones de ARS"
        );

        escribir(
            "detalle-provincias",
            "Provincia de la dirección de envío. Pedidos válidos · " +
                descripcionMonto + "."
        );

        const ventasFiltradas = datos.ventas.filter(fila =>
            coincideFecha(fila, periodo) &&
            (todosCanales || fila.channel_key === canal) &&
            (todasProvincias || fila.province_key === provincia)
        );

        const productosFiltrados = datos.ventasProducto.filter(fila =>
            coincideFecha(fila, periodo) &&
            (todosCanales || fila.channel_key === canal) &&
            (todasProvincias || fila.province_key === provincia) &&
            (producto === "Todos los productos" ||
                fila.product_key === producto)
        );

        let centavos = 0;
        let pedidos = 0;

        for (const fila of ventasFiltradas) {
            centavos += Math.round(numero(fila[columnaMonto]) * 100);
            pedidos += numero(fila.pedidos_vendidos);
        }

        // Ticket, usuarios y NPS se leen ya calculados desde los marts.
        const ticket = elegirUnaFila(datos.tickets, fila =>
            fila.periodo === periodo &&
            fila.canal === canalNombre &&
            fila.provincia === provinciaNombre
        );

        const actividad = elegirUnaFila(datos.usuarios, fila =>
            fila.periodo === periodo
        );

        const nps = elegirUnaFila(datos.nps, fila =>
            fila.periodo === periodo &&
            fila.canal === canalNombre
        );

        escribir(
            "valor-ventas",
            "$ " + formato(centavos / 100 / 1000000, 2) + " M"
        );

        escribir("valor-pedidos", formato(pedidos));

        escribir(
            "valor-ticket",
            ticket
                ? "$ " + formato(numero(ticket.ticket_promedio) / 1000, 2) +
                    " mil"
                : "Sin datos"
        );

        escribir(
            "valor-usuarios",
            actividad
                ? formato(numero(actividad.usuarios_activos))
                : "Sin datos"
        );

        escribir(
            "valor-nps",
            nps ? formato(numero(nps.nps), 1) : "Sin datos"
        );

        const ventasMensuales = agruparImportes(
            ventasFiltradas,
            fila => fila.date_key.slice(0, 4) + "-" +
                fila.date_key.slice(4, 6),
            columnaMonto
        ).map(([mes, importe]) => ({ mes, valor: importe }));

        dibujarSerie(
            "grafico-ventas", ventasMensuales, "columnas", "ventas"
        );

        const nombresProvincias = new Map(
            datos.provincias.map(fila => [fila.province_key, fila.name])
        );

        const ventasProvincias = agruparImportes(
            ventasFiltradas,
            fila => fila.province_key || "sin-provincia",
            columnaMonto
        ).map(([clave, importe]) => ({
            nombre: nombresProvincias.get(clave) ?? "Sin provincia",
            importe
        }));

        dibujarBarras("grafico-provincias", ventasProvincias);

        const actividadMensual = datos.usuarios
            .filter(fila =>
                fila.periodo !== "Todo el período" &&
                (periodo === "Todo el período" || fila.periodo === periodo)
            )
            .map(fila => ({
                mes: fila.periodo,
                valor: numero(fila.usuarios_activos)
            }));

        const npsMensual = datos.nps
            .filter(fila =>
                fila.periodo !== "Todo el período" &&
                fila.canal === canalNombre &&
                (periodo === "Todo el período" || fila.periodo === periodo)
            )
            .map(fila => ({
                mes: fila.periodo,
                valor: numero(fila.nps)
            }));

        dibujarSerie(
            "grafico-usuarios", actividadMensual, "area", "usuarios"
        );

        // Se restaura el NPS mensual en columnas.
        dibujarSerie(
            "grafico-nps", npsMensual, "columnas", "nps"
        );

        const nombresProductos = new Map(
            datos.productos.map(fila => [fila.product_key, fila.name])
        );

        const ranking = agruparImportes(
            productosFiltrados,
            fila => fila.product_key,
            "ventas_producto"
        ).map(([clave, importe]) => ({
            nombre: nombresProductos.get(clave) ?? "Producto desconocido",
            importe
        }));

        escribir(
            "titulo-ranking",
            periodo === "Todo el período"
                ? "Ranking de productos — todo el período"
                : "Ranking de productos — " + nombreMes(periodo)
        );

        dibujarRanking(ranking);
        dibujarDistribucionNPS(nps);
    } catch (error) {
        mostrarError(error);
    }
}

function mostrarSVG(contenedor, contenido, ancho, alto, descripcion) {
    contenedor.innerHTML = `
        <svg
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 ${ancho} ${alto}"
            role="img"
            aria-label="${escapar(descripcion)}"
            style="display:block;width:100%;height:auto"
        >
            ${contenido}
        </svg>
    `;
}

// Distribución NPS: barra dividida en tres categorías.
// Utiliza los porcentajes ya calculados en SQL.
function dibujarDistribucionNPS(fila) {
    const contenedor = elemento("grafico-distribucion");
    contenedor.replaceChildren();

    if (!fila || numero(fila.total_respuestas) === 0) {
        contenedor.textContent = "No hay respuestas para esta selección.";
        return;
    }

    const categorias = [
        {
            nombre: "Detractores",
            porcentaje: numero(fila.porcentaje_detractores),
            cantidad: numero(fila.detractores),
            color: colores.detractores
        },
        {
            nombre: "Pasivos",
            porcentaje: numero(fila.porcentaje_pasivos),
            cantidad: numero(fila.pasivos),
            color: colores.pasivos
        },
        {
            nombre: "Promotores",
            porcentaje: numero(fila.porcentaje_promotores),
            cantidad: numero(fila.promotores),
            color: colores.promotores
        }
    ];

    const barra = document.createElement("div");

    Object.assign(barra.style, {
        display: "flex",
        height: "38px",
        borderRadius: "8px",
        overflow: "hidden",
        margin: "26px 0 20px"
    });

    for (const categoria of categorias) {
        const segmento = document.createElement("div");

        segmento.style.flex = "0 0 " + categoria.porcentaje + "%";
        segmento.style.background = categoria.color;

        const descripcion = categoria.nombre + ": " +
            formato(categoria.porcentaje, 2) + "% · " +
            formato(categoria.cantidad) + " respuestas";

        segmento.title = descripcion;
        segmento.setAttribute("role", "img");
        segmento.setAttribute("aria-label", descripcion);
        segmento.tabIndex = 0;

        barra.appendChild(segmento);
    }

    contenedor.appendChild(barra);

    for (const categoria of categorias) {
        const linea = document.createElement("div");

        Object.assign(linea.style, {
            display: "flex",
            justifyContent: "space-between",
            gap: "12px",
            marginBottom: "14px",
            fontSize: "13px"
        });

        const nombre = document.createElement("span");
        nombre.textContent = categoria.nombre;

        const detalle = document.createElement("strong");
        detalle.textContent =
            formato(categoria.porcentaje, 2) + "% · " +
            formato(categoria.cantidad);

        linea.append(nombre, detalle);
        contenedor.appendChild(linea);
    }

    const total = document.createElement("p");

    total.style.fontSize = "12px";
    total.style.color = "#63756a";

    total.textContent =
        "Total: " + formato(numero(fila.total_respuestas)) +
        " respuestas. Porcentajes calculados en SQL.";

    contenedor.appendChild(total);
}

// Comparación de ventas entre provincias.
function dibujarBarras(id, resultados) {
    const contenedor = elemento(id);
    contenedor.replaceChildren();

    const ordenados = [...resultados].sort((a, b) =>
        b.importe - a.importe || a.nombre.localeCompare(b.nombre)
    );

    if (ordenados.length === 0) {
        contenedor.textContent = "No hay ventas para esta selección.";
        return;
    }

    const maximo = Math.max(...ordenados.map(fila => fila.importe), 1);
    const paleta = [
        colores.oscuro,
        "#527c65",
        colores.salvia,
        colores.oliva
    ];

    contenedor.style.marginTop = "24px";

    ordenados.forEach((resultado, indice) => {
        const fila = document.createElement("div");
        fila.style.marginBottom = "26px";

        const encabezado = document.createElement("div");

        Object.assign(encabezado.style, {
            display: "flex",
            flexWrap: "wrap",
            justifyContent: "space-between",
            gap: "8px",
            marginBottom: "8px",
            fontSize: "12px"
        });

        const etiqueta = document.createElement("span");
        etiqueta.textContent = resultado.nombre;

        const valor = document.createElement("strong");
        valor.textContent =
            "$ " + formato(resultado.importe / 1000000, 2) + " M";

        encabezado.append(etiqueta, valor);

        const fondo = document.createElement("div");

        Object.assign(fondo.style, {
            background: "#edf1eb",
            borderRadius: "5px",
            overflow: "hidden",
            height: "16px"
        });

        const barra = document.createElement("div");

        Object.assign(barra.style, {
            width: (resultado.importe / maximo * 100) + "%",
            height: "100%",
            background: paleta[indice % paleta.length],
            borderRadius: "5px"
        });

        const descripcion = resultado.nombre + ": $ " +
            formato(resultado.importe, 2);

        fondo.title = descripcion;
        fondo.setAttribute("role", "img");
        fondo.setAttribute("aria-label", descripcion);
        fondo.tabIndex = 0;

        fondo.appendChild(barra);
        fila.append(encabezado, fondo);
        contenedor.appendChild(fila);
    });
}

// Ranking con una línea y un punto por producto.
function dibujarRanking(resultados) {
    const contenedor = elemento("grafico-productos");
    contenedor.replaceChildren();

    const ordenados = [...resultados].sort((a, b) =>
        b.importe - a.importe || a.nombre.localeCompare(b.nombre)
    );

    if (ordenados.length === 0) {
        contenedor.textContent = "No hay ventas para esta selección.";
        return;
    }

    const maximo = Math.max(...ordenados.map(fila => fila.importe), 1);
    const ancho = 760;
    const alto = 65 + ordenados.length * 85;
    const inicio = 230;
    const recorrido = 340;

    let contenido = "";

    ordenados.forEach((fila, indice) => {
        const y = 55 + indice * 85;
        const x = inicio + fila.importe / maximo * recorrido;
        const color = indice === 0 ? colores.oscuro : "#668d73";

        contenido += `
            <circle cx="22" cy="${y}" r="16" fill="#e8efe8"/>
            <text x="22" y="${y + 5}" text-anchor="middle"
                  font-size="13" font-weight="650" fill="${colores.oscuro}">
                ${indice + 1}
            </text>

            <text x="50" y="${y + 5}" font-size="14"
                  font-weight="600" fill="${colores.oscuro}">
                ${escapar(fila.nombre)}
            </text>

            <line x1="${inicio}" y1="${y}"
                  x2="${inicio + recorrido}" y2="${y}"
                  stroke="#e8efe8" stroke-width="5"
                  stroke-linecap="round"/>

            <line x1="${inicio}" y1="${y}" x2="${x}" y2="${y}"
                  stroke="${color}" stroke-width="5"
                  stroke-linecap="round"/>

            <circle cx="${x}" cy="${y}" r="9" fill="${color}" tabindex="0">
                <title>${escapar(fila.nombre)}: $ ${
                    formato(fila.importe, 2)
                }</title>
            </circle>

            <text x="740" y="${y + 5}" text-anchor="end"
                  font-size="14" font-weight="650" fill="${colores.oscuro}">
                $ ${formato(fila.importe / 1000000, 2)} M
            </text>
        `;
    });

    contenedor.style.overflowX = "auto";

    const envoltorio = document.createElement("div");
    envoltorio.style.minWidth = "550px";

    mostrarSVG(
        envoltorio,
        contenido,
        ancho,
        alto,
        "Ranking de productos ordenados por importe vendido"
    );

    contenedor.appendChild(envoltorio);
}

// Columnas para ventas y NPS; área para usuarios.
function dibujarSerie(id, datosOriginales, tipo, unidad) {
    const contenedor = elemento(id);
    contenedor.replaceChildren();

    const serie = [...datosOriginales]
        .sort((a, b) => a.mes.localeCompare(b.mes));

    if (serie.length === 0) {
        contenedor.textContent = "No hay datos para esta selección.";
        return;
    }

    const ancho = 900;
    const alto = 350;
    const izquierda = 78;
    const derecha = 880;
    const arriba = 25;
    const abajo = 260;
    const anchoUtil = derecha - izquierda;
    const altoUtil = abajo - arriba;

    const valores = serie.map(dato => dato.valor);
    const menor = Math.min(0, ...valores);
    const mayor = Math.max(0, ...valores);
    const margen = Math.max((mayor - menor) * 0.15, 1);
    const minimo = menor < 0 ? menor - margen : 0;
    const maximo = mayor + margen;
    const rango = maximo - minimo;

    const posicionY = valor =>
        abajo - (valor - minimo) / rango * altoUtil;

    const espacio = anchoUtil / serie.length;
    const anchoBarra = Math.min(espacio * 0.62, 52);

    const puntos = serie.map((dato, indice) => ({
        x: izquierda + espacio * (indice + 0.5),
        y: posicionY(dato.valor),
        dato
    }));

    function etiquetaEje(valor) {
        if (unidad === "ventas") {
            return "$ " + formato(valor / 1000000, 1) + " M";
        }

        return formato(valor, unidad === "nps" ? 1 : 0);
    }

    function etiquetaCompleta(valor) {
        if (unidad === "ventas") return "$ " + formato(valor, 2);
        if (unidad === "nps") return formato(valor, 1) + " puntos";
        return formato(valor) + " usuarios activos";
    }

    let contenido = "";

    for (let paso = 0; paso <= 4; paso++) {
        const valor = minimo + rango * paso / 4;
        const y = posicionY(valor);

        contenido += `
            <line x1="${izquierda}" y1="${y}"
                  x2="${derecha}" y2="${y}"
                  stroke="${colores.grilla}" stroke-dasharray="3 5"/>
            <text x="${izquierda - 12}" y="${y + 4}"
                  text-anchor="end" font-size="12" fill="${colores.texto}">
                ${etiquetaEje(valor)}
            </text>
        `;
    }

    const cero = posicionY(0);

    contenido += `
        <line x1="${izquierda}" y1="${cero}"
              x2="${derecha}" y2="${cero}" stroke="#b5c5b8"/>
    `;

    if (tipo === "area") {
        const primerPunto = puntos[0];
        const ultimoPunto = puntos[puntos.length - 1];

        const recorrido = puntos.length === 1
            ? `${primerPunto.x - 20},${primerPunto.y} ${
                primerPunto.x + 20
            },${primerPunto.y}`
            : puntos.map(punto => `${punto.x},${punto.y}`).join(" ");

        const inicioArea = puntos.length === 1
            ? primerPunto.x - 20
            : primerPunto.x;

        const finArea = puntos.length === 1
            ? ultimoPunto.x + 20
            : ultimoPunto.x;

        contenido += `
            <defs>
                <linearGradient id="degradado-${id}" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stop-color="${colores.salvia}"
                          stop-opacity="0.65"/>
                    <stop offset="100%" stop-color="${colores.salvia}"
                          stop-opacity="0.08"/>
                </linearGradient>
            </defs>

            <polygon
                points="${inicioArea},${cero} ${recorrido} ${finArea},${cero}"
                fill="url(#degradado-${id})"
            />
        `;
    }

    if (tipo === "linea" || tipo === "area") {
        contenido += `
            <polyline
                points="${puntos.map(punto => `${punto.x},${punto.y}`).join(" ")}"
                fill="none" stroke="${colores.oscuro}"
                stroke-width="3" stroke-linejoin="round"
                stroke-linecap="round"
            />
        `;
    }

    puntos.forEach((punto, indice) => {
        const { x, y, dato } = punto;

        const descripcion = escapar(
            nombreMes(dato.mes) + ": " + etiquetaCompleta(dato.valor)
        );

        if (tipo === "columnas") {
            const color = dato.mes.startsWith("2024")
                ? colores.oscuro
                : colores.oliva;

            contenido += `
                <rect
                    x="${x - anchoBarra / 2}"
                    y="${Math.min(y, cero)}"
                    width="${anchoBarra}"
                    height="${Math.abs(cero - y)}"
                    rx="4" fill="${color}" tabindex="0"
                >
                    <title>${descripcion}</title>
                </rect>
            `;
        } else {
            contenido += `
                <circle cx="${x}" cy="${y}" r="5"
                        fill="${colores.oscuro}"
                        stroke="white" stroke-width="2" tabindex="0">
                    <title>${descripcion}</title>
                </circle>
            `;
        }

        const mostrarEtiqueta =
            serie.length <= 12 ||
            indice % 2 === 0 ||
            indice === serie.length - 1;

        if (mostrarEtiqueta) {
            contenido += `
                <text transform="translate(${x},282) rotate(-35)"
                      text-anchor="end" font-size="12" fill="${colores.texto}">
                    ${mesCorto(dato.mes)}
                </text>
            `;
        }
    });

    const descripciones = {
        ventas: "Ventas mensuales en pesos argentinos",
        usuarios: "Evolución mensual del indicador de usuarios activos",
        nps: "Evolución mensual del NPS en puntos"
    };

    contenedor.style.overflowX = "auto";

    const envoltorio = document.createElement("div");
    envoltorio.style.minWidth = "520px";

    mostrarSVG(
        envoltorio,
        contenido,
        ancho,
        alto,
        descripciones[unidad]
    );

    contenedor.appendChild(envoltorio);
}

function mostrarError(error) {
    console.error(error);

    for (const id of [
        "grafico-ventas",
        "grafico-provincias",
        "grafico-usuarios",
        "grafico-nps",
        "grafico-productos",
        "grafico-distribucion"
    ]) {
        const contenedor = elemento(id);

        if (contenedor) {
            contenedor.textContent =
                "No se pudo cargar el gráfico. Revisá el servidor y los CSV.";
        }
    }

    for (const nombre of ["ventas", "pedidos", "ticket", "usuarios", "nps"]) {
        escribir("valor-" + nombre, "Error de carga");
    }
}

async function iniciarDashboard() {
    try {
        const nombres = [
            ["ventas", "mart_ventas_diarias.csv"],
            ["tickets", "mart_ticket_periodos.csv"],
            ["usuarios", "mart_usuarios_periodos.csv"],
            ["nps", "mart_nps_periodos.csv"],
            ["canales", "dim_channel.csv"],
            ["provincias", "dim_province.csv"],
            ["ventasProducto", "mart_ventas_producto_diarias.csv"],
            ["productos", "dim_product.csv"]
        ];

        const archivos = await Promise.all(
            nombres.map(([, archivo]) => leerCSV(archivo))
        );

        nombres.forEach(([clave], indice) => {
            datos[clave] = archivos[indice];
        });

        cargarSelectores();

        for (const id of [
            "filtro-periodo",
            "filtro-canal",
            "filtro-provincia",
            "filtro-producto",
            "filtro-monto"
        ]) {
            elemento(id).addEventListener("change", actualizarDashboard);
        }

        elemento("limpiar-filtros").addEventListener("click", () => {
            const valores = {
                "filtro-periodo": "Todo el período",
                "filtro-canal": "Todos los canales",
                "filtro-provincia": "Todas las provincias",
                "filtro-producto": "Todos los productos",
                "filtro-monto": "ventas_con_iva_y_envio"
            };

            for (const [id, valor] of Object.entries(valores)) {
                elemento(id).value = valor;
            }

            actualizarDashboard();
        });

        actualizarDashboard();
    } catch (error) {
        mostrarError(error);
    }
}

iniciarDashboard();