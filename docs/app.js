let ventas = [];
let tickets = [];
let usuarios = [];
let respuestasNPS = [];
let canales = [];
let provincias = [];

// Los CSV actuales que leemos aquí no contienen comas internas.
async function leerCSV(nombre) {
    const respuesta = await fetch("../dw/" + nombre);

    if (!respuesta.ok) {
        throw new Error("No se pudo leer " + nombre);
    }

    const texto = await respuesta.text();
    const filas = texto.replace(/^\uFEFF/, "").trim().split(/\r?\n/);
    const encabezados = filas[0].split(",");

    return filas.slice(1)
        .filter(fila => fila.trim())
        .map(fila => {
            const valores = fila.split(",");

            if (valores.length !== encabezados.length) {
                throw new Error("Fila inesperada en " + nombre);
            }

            return Object.fromEntries(
                encabezados.map((nombre, i) => [nombre, valores[i]])
            );
        });
}

function numero(valor) {
    if (valor === undefined || valor === null || valor.trim() === "") {
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

function elegirUnaFila(datos, condicion) {
    const filas = datos.filter(condicion);

    if (filas.length > 1) {
        throw new Error("Hay varios resultados para la misma selección.");
    }

    return filas[0] ?? null;
}

function agregarOpcion(selector, valor, etiqueta) {
    const opcion = document.createElement("option");
    opcion.value = valor;
    opcion.textContent = etiqueta;
    selector.appendChild(opcion);
}

function cargarSelectores() {
    const selectorPeriodo = document.getElementById("filtro-periodo");
    const selectorCanal = document.getElementById("filtro-canal");
    const selectorProvincia = document.getElementById("filtro-provincia");

    const meses = [...new Set(
        usuarios
            .map(fila => fila.periodo)
            .filter(periodo => periodo !== "Todo el período")
    )].sort();

    for (const mes of meses) {
        const [anio, numeroMes] = mes.split("-");
        const fecha = new Date(Number(anio), Number(numeroMes) - 1, 1);

        agregarOpcion(
            selectorPeriodo,
            mes,
            fecha.toLocaleDateString("es-AR", {
                month: "long",
                year: "numeric"
            })
        );
    }

    for (const canal of canales) {
        agregarOpcion(selectorCanal, canal.channel_key, canal.name);
    }

    for (const provincia of provincias) {
        agregarOpcion(
            selectorProvincia,
            provincia.province_key,
            provincia.name
        );
    }
}

function actualizarTarjetas() {
    try {
        const periodo = document.getElementById("filtro-periodo").value;
        const canalKey = document.getElementById("filtro-canal").value;
        const provinciaKey =
            document.getElementById("filtro-provincia").value;

        const esTotal = periodo === "Todo el período";
        const todosCanales = canalKey === "Todos los canales";
        const todasProvincias = provinciaKey === "Todas las provincias";

        const canalNombre = todosCanales
            ? "Todos los canales"
            : canales.find(canal => canal.channel_key === canalKey)?.name;

        const provinciaNombre = todasProvincias
            ? "Todas las provincias"
            : provincias.find(
                provincia => provincia.province_key === provinciaKey
            )?.name;

        if (!canalNombre || !provinciaNombre) {
            throw new Error("No se reconoce el canal o la provincia.");
        }

        const ventasFiltradas = ventas.filter(fila => {
            const coincidePeriodo = esTotal ||
                fila.date_key.slice(0, 6) === periodo.replace("-", "");

            const coincideCanal = todosCanales ||
                fila.channel_key === canalKey;

            const coincideProvincia = todasProvincias ||
                fila.province_key === provinciaKey;

            return coincidePeriodo &&
                coincideCanal &&
                coincideProvincia;
        });

        dibujarVentasMensuales(ventasFiltradas);

        let ventasEnCentavos = 0;
        let pedidos = 0;

        for (const fila of ventasFiltradas) {
            ventasEnCentavos += Math.round(
                numero(fila.ventas_con_iva_y_envio) * 100
            );

            pedidos += numero(fila.pedidos_vendidos);
        }

        // Estos indicadores ya vienen calculados desde SQL.
        const ticket = elegirUnaFila(tickets, fila =>
            fila.periodo === periodo &&
            fila.canal === canalNombre &&
            fila.provincia === provinciaNombre
        );

        const actividad = elegirUnaFila(usuarios, fila =>
            fila.periodo === periodo
        );

        const nps = elegirUnaFila(respuestasNPS, fila =>
            fila.periodo === periodo &&
            fila.canal === canalNombre
        );

        document.getElementById("valor-ventas").textContent =
            "$ " + formato(ventasEnCentavos / 100 / 1000000, 2) + " M";

        document.getElementById("valor-pedidos").textContent =
            formato(pedidos);

        document.getElementById("valor-ticket").textContent = ticket
            ? "$ " + formato(numero(ticket.ticket_promedio) / 1000, 2) +
                " mil"
            : "Sin datos";

        document.getElementById("valor-usuarios").textContent = actividad
            ? formato(numero(actividad.usuarios_activos))
            : "Sin datos";

        document.getElementById("valor-nps").textContent = nps
            ? formato(numero(nps.nps), 1)
            : "Sin datos";
    } catch (error) {
        mostrarError(error);
    }
}

function dibujarVentasMensuales(filas) {
    const contenedor = document.getElementById("grafico-ventas");
    const importesPorMes = new Map();

    for (const fila of filas) {
        const clave = fila.date_key;
        const mes = clave.slice(0, 4) + "-" + clave.slice(4, 6);

        const centavos = Math.round(
            numero(fila.ventas_con_iva_y_envio) * 100
        );

        importesPorMes.set(
            mes,
            (importesPorMes.get(mes) ?? 0) + centavos
        );
    }

    const datos = [...importesPorMes.entries()]
        .sort(([mesA], [mesB]) => mesA.localeCompare(mesB))
        .map(([mes, centavos]) => ({
            mes,
            importe: centavos / 100
        }));

    if (datos.length === 0) {
        contenedor.textContent = "No hay ventas para esta selección.";
        return;
    }

    const ancho = 1000;
    const alto = 380;
    const izquierda = 85;
    const derecha = 20;
    const arriba = 25;
    const abajo = 85;

    const anchoUtil = ancho - izquierda - derecha;
    const altoUtil = alto - arriba - abajo;

    const maximo = Math.max(
        ...datos.map(dato => dato.importe),
        1
    ) * 1.15;

    const espacio = anchoUtil / datos.length;
    const anchoBarra = Math.min(espacio * 0.65, 65);

    let contenido = "";

    // Escala vertical en millones de pesos, comenzando en cero.
    for (let paso = 0; paso <= 4; paso++) {
        const valor = maximo * paso / 4;
        const y = arriba + altoUtil - valor / maximo * altoUtil;

        contenido += `
            <line
                x1="${izquierda}" y1="${y}"
                x2="${ancho - derecha}" y2="${y}"
                stroke="#e4ebe6"
            />
            <text
                x="${izquierda - 12}" y="${y + 4}"
                text-anchor="end"
                font-size="13" fill="#52685b"
            >
                $ ${formato(valor / 1000000, 1)} M
            </text>
        `;
    }

    for (let i = 0; i < datos.length; i++) {
        const dato = datos[i];
        const alturaBarra = dato.importe / maximo * altoUtil;
        const centro = izquierda + espacio * (i + 0.5);
        const x = centro - anchoBarra / 2;
        const y = arriba + altoUtil - alturaBarra;

        const color = dato.mes.startsWith("2024")
            ? "var(--verde-oscuro)"
            : "var(--verde-oliva)";

        contenido += `
            <rect
                class="barra-ventas"
                x="${x}" y="${y}"
                width="${anchoBarra}" height="${alturaBarra}"
                rx="3" fill="${color}" tabindex="0"
            >
                <title>${dato.mes}: $ ${formato(dato.importe, 2)}</title>
            </rect>

            <text
                transform="translate(${centro}, ${arriba + altoUtil + 18})
                           rotate(-45)"
                text-anchor="end"
                font-size="13" fill="#52685b"
            >
                ${dato.mes}
            </text>
        `;
    }

    contenedor.innerHTML = `
        <svg
            viewBox="0 0 ${ancho} ${alto}"
            role="img"
            aria-label="Ventas mensuales en pesos argentinos"
        >
            ${contenido}
        </svg>
    `;
}

function mostrarError(error) {
    console.error(error);

    document.getElementById("grafico-ventas").textContent =
        "No se pudo actualizar el gráfico. Revisá el servidor y los CSV.";

    for (const nombre of ["ventas", "pedidos", "ticket", "usuarios", "nps"]) {
        document.getElementById("valor-" + nombre).textContent =
            "Error de carga";
    }
}

async function iniciarDashboard() {
    try {
        [
            ventas,
            tickets,
            usuarios,
            respuestasNPS,
            canales,
            provincias
        ] = await Promise.all([
            leerCSV("mart_ventas_diarias.csv"),
            leerCSV("mart_ticket_periodos.csv"),
            leerCSV("mart_usuarios_periodos.csv"),
            leerCSV("mart_nps_periodos.csv"),
            leerCSV("dim_channel.csv"),
            leerCSV("dim_province.csv")
        ]);

        cargarSelectores();

        for (const id of [
            "filtro-periodo",
            "filtro-canal",
            "filtro-provincia"
        ]) {
            document.getElementById(id)
                .addEventListener("change", actualizarTarjetas);
        }

        document.getElementById("limpiar-filtros")
            .addEventListener("click", () => {
                document.getElementById("filtro-periodo").value =
                    "Todo el período";

                document.getElementById("filtro-canal").value =
                    "Todos los canales";

                document.getElementById("filtro-provincia").value =
                    "Todas las provincias";

                actualizarTarjetas();
            });

        actualizarTarjetas();
    } catch (error) {
        mostrarError(error);
    }
}

iniciarDashboard();