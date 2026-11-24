import { useCallback, useEffect, useMemo, useState, type FormEvent } from 'react'
import {
  Activity, ArrowDownToLine, ArrowUpRight, BookOpen, Check, ChevronDown,
  CircleAlert, CloudUpload, FileText, Heart, LayoutDashboard, Library,
  LogOut, Menu, PackageCheck, Plus, Search, Settings2, ShoppingBag,
  Trash2, Users, X,
} from 'lucide-react'
import { isSupabaseConfigured, supabase, type Book, type Customer, type Order } from './supabase'
import './App.css'

type Section = 'overview' | 'books' | 'documents' | 'orders' | 'users' | 'schema'
type OrderStatus = { value: string; label: string }
type DbColumn = { name: string; type: string; udt_name: string; nullable: boolean; default: string | null; identity: boolean; generated: boolean; ordinal: number; primary_key: boolean }
type DbForeignKey = { column: string; referenced_schema: string; referenced_table: string; referenced_column: string; constraint: string }
type DbTable = { name: string; columns: DbColumn[]; foreign_keys: DbForeignKey[] }
type DbSchema = { tables: DbTable[] }
const emptyForeignKeys: DbForeignKey[] = []
const formatName = (path: string | null) => path?.split('.').pop()?.toUpperCase() ?? 'MANQUANT'
const money = (amount: number) => new Intl.NumberFormat('fr-FR').format(amount) + ' FCFA'

export default function App() {
  const [session, setSession] = useState<Awaited<ReturnType<NonNullable<typeof supabase>['auth']['getSession']>>['data']['session']>(null)
  const [admin, setAdmin] = useState(false)
  const [checking, setChecking] = useState(true)
  const [section, setSection] = useState<Section>('overview')
  const [books, setBooks] = useState<Book[]>([])
  const [orders, setOrders] = useState<Order[]>([])
  const [availableOrderStatuses, setAvailableOrderStatuses] = useState<OrderStatus[]>(defaultOrderStatuses)
  const [customers, setCustomers] = useState<Customer[]>([])
  const [dbSchema, setDbSchema] = useState<DbSchema | null>(null)
  const [search, setSearch] = useState('')
  const [notice, setNotice] = useState<{ text: string; bad?: boolean } | null>(null)
  const [loading, setLoading] = useState(false)
  const [editing, setEditing] = useState<Book | null | false>(false)
  const [editingCustomer, setEditingCustomer] = useState<Customer | null | false>(false)
  const [loginEmail, setLoginEmail] = useState('')
  const [loginPassword, setLoginPassword] = useState('')
  const [mobileMenu, setMobileMenu] = useState(false)

  const flash = useCallback((text: string, bad = false) => {
    setNotice({ text, bad })
    window.setTimeout(() => setNotice(null), 4500)
  }, [])

  const loadData = useCallback(async () => {
    if (!supabase) return
    setLoading(true)
    const [bookResult, orderResult, usersResult, statusResult, schemaResult] = await Promise.all([
      supabase.from('books').select('*').order('title'),
      supabase.from('orders').select('id,user_id,total_price,status,created_at,book_ids').order('created_at', { ascending: false }).limit(100),
      supabase.rpc('get_admin_users'),
      supabase.rpc('get_admin_order_statuses'),
      supabase.rpc('get_admin_schema'),
    ])
    if (bookResult.error) flash(bookResult.error.message, true)
    else setBooks((bookResult.data ?? []) as Book[])
    if (orderResult.error) flash(orderResult.error.message, true)
    else setOrders((orderResult.data ?? []) as Order[])
    if (usersResult.error) {
      setCustomers([])
      flash('La gestion des utilisateurs manque. Appliquez la migration admin la plus récente.', true)
    } else setCustomers((usersResult.data ?? []) as Customer[])
    if (statusResult.error) {
      setAvailableOrderStatuses(defaultOrderStatuses)
      flash('Les statuts de commande ne sont pas configurés. Appliquez la migration admin la plus récente.', true)
    } else setAvailableOrderStatuses(((statusResult.data ?? []) as string[]).map(value => ({ value, label: orderStatusLabel(value) })))
    if (schemaResult.error) {
      setDbSchema(null)
      flash('Le schéma admin manque. Appliquez la dernière migration Supabase.', true)
    } else setDbSchema(schemaResult.data as DbSchema)
    setLoading(false)
  }, [flash])

  useEffect(() => {
    if (!supabase) { setChecking(false); return }
    let mounted = true
    supabase.auth.getSession().then(({ data }) => {
      if (mounted) setSession(data.session)
    }).finally(() => { if (mounted) setChecking(false) })
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, next) => {
      setSession(next)
      if (!next) { setAdmin(false); setBooks([]); setOrders([]); setCustomers([]) }
    })
    return () => { mounted = false; subscription.unsubscribe() }
  }, [])

  useEffect(() => {
    if (!session || !supabase) return
    let alive = true
    supabase.from('admin_users').select('user_id').eq('user_id', session.user.id).maybeSingle()
      .then(({ data, error }) => {
        if (!alive) return
        if (error) flash('Droits admin indisponibles. Appliquez la migration admin.', true)
        setAdmin(Boolean(data))
      })
    return () => { alive = false }
  }, [session, flash])

  useEffect(() => { if (admin) void loadData() }, [admin, loadData])

  const filteredBooks = useMemo(() => {
    const query = search.trim().toLowerCase()
    if (!query) return books
    return books.filter(book => [book.title, book.author, book.category].some(value => value?.toLowerCase().includes(query)))
  }, [books, search])

  const missingFiles = books.filter(book => !book.reading_path).length
  const pendingOrders = orders.filter(order => order.status === 'en_attente').length

  async function signIn(event: FormEvent) {
    event.preventDefault()
    if (!supabase) return
    const { error } = await supabase.auth.signInWithPassword({ email: loginEmail, password: loginPassword })
    if (error) flash(error.message, true)
  }

  async function signOut() { await supabase?.auth.signOut() }

  if (!isSupabaseConfigured) return <Configuration />
  if (checking) return <div className="boot-screen"><div className="brand-mark"><BookOpen /></div><span>Chargement de votre espace…</span></div>
  if (!session) return <Login email={loginEmail} password={loginPassword} setEmail={setLoginEmail} setPassword={setLoginPassword} onSubmit={signIn} notice={notice} />
  if (!admin) return <AccessDenied email={session.user.email ?? ''} onSignOut={signOut} notice={notice} />

  const nav: { id: Section; label: string; icon: typeof LayoutDashboard }[] = [
    { id: 'overview', label: 'Vue d’ensemble', icon: LayoutDashboard },
    { id: 'books', label: 'Catalogue', icon: Library },
    { id: 'documents', label: 'Fichiers de lecture', icon: FileText },
    { id: 'orders', label: 'Commandes', icon: ShoppingBag },
    { id: 'users', label: 'Utilisateurs', icon: Users },
    { id: 'schema', label: 'Tables & relations', icon: Settings2 },
  ]
  const titles: Record<Section, [string, string]> = {
    overview: ['Bonjour, administrateur', 'Voici l’activité de votre librairie.'],
    books: ['Catalogue', 'Gérez les livres proposés dans l’application.'],
    documents: ['Fichiers de lecture', 'Reliez les documents aux livres de votre catalogue.'],
    orders: ['Commandes', 'Suivez les achats et mettez à jour leur avancement.'],
    users: ['Utilisateurs', 'Consultez les comptes clients et mettez à jour leurs coordonnées.'],
    schema: ['Tables & relations', 'Structure réelle exposée par la base Supabase.'],
  }

  return <div className="admin-shell">
    <aside className={`sidebar ${mobileMenu ? 'sidebar-open' : ''}`}>
      <div className="brand"><div className="brand-mark"><BookOpen size={21} /></div><div><b>Tchad Books</b><small>ESPACE ADMIN</small></div><button className="icon-button close-menu" onClick={() => setMobileMenu(false)}><X /></button></div>
      <div className="workspace-label">ESPACE DE TRAVAIL</div>
      <nav>{nav.map(item => <button key={item.id} className={`nav-item ${section === item.id ? 'active' : ''}`} onClick={() => { setSection(item.id); setMobileMenu(false) }}><item.icon size={18} /><span>{item.label}</span>{item.id === 'documents' && missingFiles > 0 && <i className="nav-count">{missingFiles}</i>}</button>)}</nav>
      <div className="sidebar-bottom"><div className="online-state"><span /> Supabase connecté</div><button className="nav-item" onClick={signOut}><LogOut size={18} /><span>Se déconnecter</span></button><div className="admin-user"><div className="avatar">{(session.user.email ?? 'A').slice(0, 1).toUpperCase()}</div><div className="user-copy"><b>Administrateur</b><small>{session.user.email}</small></div><ChevronDown size={16} /></div></div>
    </aside>
    {mobileMenu && <button aria-label="Fermer le menu" className="scrim" onClick={() => setMobileMenu(false)} />}
    <main className="main-area">
      <header className="topbar"><button className="icon-button mobile-toggle" onClick={() => setMobileMenu(true)}><Menu /></button><div className="breadcrumbs">Administration <span>/</span> <b>{titles[section][0]}</b></div><div className="topbar-right"><span className="date-label">Espace sécurisé</span><div className="avatar small-avatar">{(session.user.email ?? 'A').slice(0, 1).toUpperCase()}</div></div></header>
      <div className="page-content"><div className="page-heading"><div><div className="eyebrow">TCHAD BOOKS <span>•</span> ADMINISTRATION</div><h1>{titles[section][0]}</h1><p>{titles[section][1]}</p></div>{section === 'books' && <button className="button primary" onClick={() => setEditing(null)}><Plus size={17} /> Ajouter un livre</button>}</div>
        {loading && <div className="loading-line" />}
        {section === 'overview' && <Overview books={books} orders={orders} missingFiles={missingFiles} pendingOrders={pendingOrders} setSection={setSection} />}
        {section === 'books' && <Books books={filteredBooks} search={search} setSearch={setSearch} onEdit={book => setEditing(book)} onDelete={async book => { if (confirm(`Supprimer « ${book.title} » du catalogue ?`)) { const { error } = await supabase!.from('books').delete().eq('id', book.id); if (error) flash(error.message, true); else { setBooks(prev => prev.filter(item => item.id !== book.id)); flash('Livre supprimé du catalogue.') } } }} />}
        {section === 'documents' && <Documents books={books} onChanged={loadData} flash={flash} />}
        {section === 'orders' && <Orders orders={orders} books={books} customers={customers} statuses={availableOrderStatuses} onChanged={loadData} flash={flash} />}
        {section === 'users' && <UsersPage customers={customers} onEdit={customer => setEditingCustomer(customer)} />}
        {section === 'schema' && <SchemaExplorer schema={dbSchema} />}
      </div>
    </main>
    {editing !== false && <BookEditor book={editing || null} schema={dbSchema} close={() => setEditing(false)} saved={book => { setBooks(current => { const found = current.some(item => item.id === book.id); return found ? current.map(item => item.id === book.id ? book : item) : [...current, book].sort((a,b) => a.title.localeCompare(b.title)) }); setEditing(false); flash('Le livre a été enregistré.') }} flash={flash} />}
    {editingCustomer !== false && editingCustomer && <CustomerEditor customer={editingCustomer} close={() => setEditingCustomer(false)} saved={customer => { setCustomers(current => current.map(item => item.user_id === customer.user_id ? customer : item)); setEditingCustomer(false); flash('Les coordonnées du client ont été enregistrées.') }} flash={flash} />}
    {notice && <div className={`toast ${notice.bad ? 'toast-bad' : ''}`}><span>{notice.bad ? <CircleAlert size={18} /> : <Check size={18} />}</span>{notice.text}<button onClick={() => setNotice(null)}><X size={16} /></button></div>}
  </div>
}

function Login({ email, password, setEmail, setPassword, onSubmit, notice }: { email: string; password: string; setEmail: (v: string) => void; setPassword: (v: string) => void; onSubmit: (e: FormEvent) => void; notice: { text: string; bad?: boolean } | null }) {
  return <div className="auth-screen"><div className="auth-card"><div className="brand-mark auth-mark"><BookOpen /></div><div className="eyebrow">TCHAD BOOKS • ADMIN</div><h1>Content de vous revoir</h1><p>Connectez-vous pour gérer votre librairie.</p><form onSubmit={onSubmit}><label>Adresse e-mail<input type="email" autoComplete="username" required value={email} onChange={e => setEmail(e.target.value)} placeholder="vous@exemple.com" /></label><label>Mot de passe<input type="password" autoComplete="current-password" required value={password} onChange={e => setPassword(e.target.value)} placeholder="Votre mot de passe" /></label><button className="button primary full">Se connecter <ArrowUpRight size={17} /></button></form><div className="secure-note"><span /> Connexion sécurisée avec Supabase Auth</div>{notice && <p className="inline-error">{notice.text}</p>}</div></div>
}

function Configuration() { return <div className="auth-screen"><div className="auth-card"><div className="brand-mark auth-mark"><Settings2 /></div><div className="eyebrow">CONFIGURATION REQUISE</div><h1>Connectez Supabase</h1><p>Créez <code>admin/.env.local</code> avec les variables suivantes, puis relancez le serveur.</p><pre>VITE_SUPABASE_URL=https://…supabase.co<br />VITE_SUPABASE_ANON_KEY=…</pre><p className="muted">Utilisez uniquement la clé publique anon/publishable. N’ajoutez jamais de clé service_role à l’interface.</p></div></div> }
function AccessDenied({ email, onSignOut, notice }: { email: string; onSignOut: () => void; notice: { text: string; bad?: boolean } | null }) { return <div className="auth-screen"><div className="auth-card"><div className="brand-mark auth-mark"><CircleAlert /></div><div className="eyebrow">ACCÈS RESTREINT</div><h1>Compte non autorisé</h1><p><b>{email}</b> est connecté, mais n’a pas de droits administrateur.</p><p>Ajoutez cet utilisateur à <code>public.admin_users</code> depuis le SQL Editor Supabase.</p><button className="button secondary full" onClick={onSignOut}><LogOut size={17} /> Se déconnecter</button>{notice && <p className="inline-error">{notice.text}</p>}</div></div> }

function Overview({ books, orders, missingFiles, pendingOrders, setSection }: { books: Book[]; orders: Order[]; missingFiles: number; pendingOrders: number; setSection: (s: Section) => void }) {
  const total = orders.reduce((sum, order) => sum + Number(order.total_price || 0), 0)
  return <>
    <div className="stat-grid"><Stat icon={Library} label="Livres au catalogue" value={books.length.toString()} hint="Livres disponibles"/><Stat icon={FileText} label="Fichiers à relier" value={missingFiles.toString()} hint={missingFiles ? 'Lecture à configurer' : 'Tout est prêt'} warn={missingFiles > 0}/><Stat icon={PackageCheck} label="Commandes en attente" value={pendingOrders.toString()} hint="À prendre en charge"/><Stat icon={Activity} label="Commandes enregistrées" value={orders.length.toString()} hint={`Total cumulé : ${money(total)}`}/></div>
    {missingFiles > 0 && <div className="notice-panel"><div className="notice-icon"><CircleAlert /></div><div><b>Des fichiers de lecture sont manquants</b><p>Associez un document PDF, EPUB, TXT ou Markdown à chacun des livres concernés.</p></div><button className="button secondary" onClick={() => setSection('documents')}>Gérer les fichiers <ArrowUpRight size={16}/></button></div>}
    <div className="dashboard-grid"><section className="panel"><div className="panel-heading"><div><h2>Dernières commandes</h2><p>Activité récente dans votre librairie</p></div><button className="text-action" onClick={() => setSection('orders')}>Tout voir <ArrowUpRight size={15}/></button></div>{orders.length ? <div className="compact-list">{orders.slice(0,5).map(order => <div className="compact-row" key={order.id}><div className="row-icon"><ShoppingBag size={17}/></div><div className="row-grow"><b>Commande #{order.id.slice(0,8)}</b><small>{new Date(order.created_at).toLocaleDateString('fr-FR')}</small></div><span className="order-amount">{money(order.total_price)}</span><Status status={order.status}/></div>)}</div> : <Empty icon={ShoppingBag} title="Pas encore de commandes" text="Les nouvelles commandes apparaîtront ici."/>}</section>
    <section className="panel"><div className="panel-heading"><div><h2>Catalogue récent</h2><p>Derniers livres ajoutés</p></div><button className="text-action" onClick={() => setSection('books')}>Catalogue <ArrowUpRight size={15}/></button></div>{books.slice(0,5).map(book => <div className="compact-row" key={book.id}><Cover book={book}/><div className="row-grow"><b>{book.title}</b><small>{book.author}</small></div><span className="order-amount">{money(book.price)}</span></div>)}</section></div>
  </>
}
function Stat({ icon: Icon, label, value, hint, warn = false }: { icon: typeof Library; label: string; value: string; hint: string; warn?: boolean }) { return <div className={`stat-card ${warn ? 'stat-warn' : ''}`}><div className="stat-top"><span>{label}</span><i><Icon size={18}/></i></div><strong>{value}</strong><small>{hint}</small></div> }

function Books({ books, search, setSearch, onEdit, onDelete }: { books: Book[]; search: string; setSearch: (s: string) => void; onEdit: (b: Book) => void; onDelete: (b: Book) => void }) {
  return <section className="panel table-panel"><div className="table-tools"><div className="search-box"><Search size={17}/><input value={search} onChange={e => setSearch(e.target.value)} placeholder="Rechercher un titre, un auteur…" /></div><span className="result-count">{books.length} livre{books.length === 1 ? '' : 's'}</span></div>{books.length ? <div className="table-scroll"><table><thead><tr><th>LIVRE</th><th>CATÉGORIE</th><th>PRIX</th><th>LECTURE</th><th /></tr></thead><tbody>{books.map(book => <tr key={book.id}><td><div className="book-cell"><Cover book={book}/><div><b>{book.title}</b><small>{book.author}</small></div></div></td><td>{book.category || <span className="muted">—</span>}</td><td className="price-cell">{money(book.price)}</td><td><span className={`format-pill ${book.reading_path ? 'format-ready' : 'format-missing'}`}>{book.reading_path ? formatName(book.reading_path) : 'À CONFIGURER'}</span></td><td><div className="row-actions"><button className="icon-button" title="Modifier" onClick={() => onEdit(book)}><Settings2 size={17}/></button><button className="icon-button danger-action" title="Supprimer" onClick={() => onDelete(book)}><Trash2 size={17}/></button></div></td></tr>)}</tbody></table></div> : <Empty icon={Search} title="Aucun livre trouvé" text="Essayez un autre titre ou ajoutez un livre au catalogue."/>}</section>
}

function Documents({ books, onChanged, flash }: { books: Book[]; onChanged: () => void; flash: (text: string, bad?: boolean) => void }) {
  const [selected, setSelected] = useState('')
  const [file, setFile] = useState<File | null>(null)
  const [busy, setBusy] = useState(false)
  const [filter, setFilter] = useState('all')
  const filtered = books.filter(book => filter === 'all' || (filter === 'missing' ? !book.reading_path : Boolean(book.reading_path)))
  async function upload(event: FormEvent) {
    event.preventDefault()
    if (!supabase || !selected || !file) return
    const allowed = ['pdf', 'epub', 'txt', 'md', 'markdown']
    const ext = file.name.split('.').pop()?.toLowerCase() ?? ''
    if (!allowed.includes(ext)) { flash('Format non pris en charge. Choisissez PDF, EPUB, TXT ou Markdown.', true); return }
    const book = books.find(item => item.id === selected)
    if (!book) return
    setBusy(true)
    const safeName = file.name.normalize('NFKD').replace(/[\u0300-\u036f]/g, '').replace(/[^a-zA-Z0-9._-]+/g, '-')
    const path = `${book.id}/${Date.now()}-${safeName}`
    const { error: uploadError } = await supabase.storage.from('book-files').upload(path, file, { upsert: true, contentType: file.type || 'application/octet-stream' })
    if (uploadError) { flash(uploadError.message, true); setBusy(false); return }
    const { error: updateError } = await supabase.from('books').update({ reading_path: path }).eq('id', book.id)
    if (updateError) { flash(`Fichier envoyé mais association impossible : ${updateError.message}`, true); setBusy(false); return }
    flash(`Document relié à « ${book.title} ».`)
    setFile(null); setSelected(''); setBusy(false); onChanged()
  }
  return <div className="documents-layout"><section className="panel upload-panel"><div className="panel-heading"><div><h2>Ajouter un document</h2><p>Formats acceptés : PDF, EPUB, TXT, Markdown</p></div><div className="upload-icon"><CloudUpload/></div></div><form onSubmit={upload}><label className="field-label">Livre à compléter ou remplacer<select required value={selected} onChange={e => setSelected(e.target.value)}><option value="">Choisir un livre…</option>{books.map(book => <option key={book.id} value={book.id}>{book.title} — {book.author}{book.reading_path ? ' (remplacer le fichier)' : ''}</option>)}</select></label><label className={`dropzone ${file ? 'dropzone-selected' : ''}`}><input type="file" accept=".pdf,.epub,.txt,.md,.markdown" onChange={e => setFile(e.target.files?.[0] ?? null)} /><span className="drop-icon">{file ? <Check/> : <ArrowDownToLine/>}</span><b>{file ? file.name : 'Choisir un fichier'}</b><small>{file ? `${(file.size / 1024 / 1024).toFixed(1)} Mo • prêt à envoyer` : 'ou déposer le document ici'}</small></label><button className="button primary full" disabled={!file || !selected || busy}>{busy ? <><span className="spinner"/> Envoi en cours…</> : <><CloudUpload size={17}/> Envoyer et relier le fichier</>}</button><p className="upload-help">Le document reste dans le stockage privé et seuls les lecteurs ayant acheté le livre peuvent y accéder.</p></form></section>
  <section className="panel files-panel"><div className="panel-heading"><div><h2>État des lectures</h2><p>{books.filter(b => b.reading_path).length} document(s) relié(s)</p></div><select className="compact-select" value={filter} onChange={e => setFilter(e.target.value)}><option value="all">Tous</option><option value="missing">À compléter</option><option value="ready">Configurés</option></select></div><div className="file-list">{filtered.map(book => <div className="file-row" key={book.id}><Cover book={book}/><div className="row-grow"><b>{book.title}</b><small>{book.reading_path ?? 'Aucun fichier relié'}</small></div>{book.reading_path ? <span className="format-pill format-ready">{formatName(book.reading_path)}</span> : <span className="format-pill format-missing">MANQUANT</span>}</div>)}</div></section></div>
}

const defaultOrderStatuses: OrderStatus[] = [
  { value: 'en_attente', label: 'En attente' },
  { value: 'confirmee', label: 'Confirmée' },
  { value: 'expediee', label: 'Expédiée' },
  { value: 'livree', label: 'Livrée' },
  { value: 'annulee', label: 'Annulée' },
]
function orderStatusLabel(status: string) { return defaultOrderStatuses.find(item => item.value === status)?.label ?? status.replaceAll('_', ' ') }

function Orders({ orders, books, customers, statuses, onChanged, flash }: { orders: Order[]; books: Book[]; customers: Customer[]; statuses: OrderStatus[]; onChanged: () => Promise<void>; flash: (text: string, bad?: boolean) => void }) {
  const [query, setQuery] = useState('')
  const [filter, setFilter] = useState('all')
  const [busyOrder, setBusyOrder] = useState<string | null>(null)
  const byId = new Map(books.map(book => [book.id, book]))
  const customerById = new Map(customers.map(customer => [customer.user_id, customer]))
  const filtered = orders.filter(order => {
    const customer = customerById.get(order.user_id)
    const bookTitles = (order.book_ids ?? []).map(id => byId.get(String(id))?.title ?? '').join(' ')
    const matchesQuery = [order.id, customer?.full_name, customer?.email, bookTitles].some(value => value?.toLowerCase().includes(query.trim().toLowerCase()))
    return matchesQuery && (filter === 'all' || order.status === filter)
  })
  async function changeStatus(order: Order, status: string) {
    if (!supabase || status === order.status) return
    setBusyOrder(order.id)
    const { error } = await supabase.rpc('admin_update_order_status', { p_order_id: order.id, p_status: status })
    if (error) flash(error.message, true)
    else { flash(`Commande #${order.id.slice(0, 8)} mise à jour.`); await onChanged() }
    setBusyOrder(null)
  }
  return <section className="panel table-panel"><div className="table-tools"><div><h2>Suivi des commandes</h2><p className="muted">Les informations de commande sont calculées lors de l’achat. Modifiez uniquement leur statut.</p></div><span className="result-count">{filtered.length} / {orders.length} commandes</span></div><div className="table-tools order-tools"><div className="search-box"><Search size={17}/><input aria-label="Rechercher une commande" value={query} onChange={e => setQuery(e.target.value)} placeholder="Référence, client ou livre…" /></div><select className="compact-select" aria-label="Filtrer par statut" value={filter} onChange={e => setFilter(e.target.value)}><option value="all">Tous les statuts</option>{statuses.map(({ value, label }) => <option key={value} value={value}>{label}</option>)}</select></div>{filtered.length ? <div className="table-scroll"><table><thead><tr><th>RÉFÉRENCE</th><th>CLIENT</th><th>LIVRES</th><th>DATE</th><th>MONTANT</th><th>STATUT / ACTION</th></tr></thead><tbody>{filtered.map(order => {
    const customer = customerById.get(order.user_id)
    return <tr key={order.id}><td><b>#{order.id.slice(0,8)}</b></td><td><b>{customer?.full_name || 'Client'}</b><small className="relation-hint">{customer?.email ?? 'Compte client'}</small></td><td><div className="order-books">{(order.book_ids ?? []).map(id => <span key={id} title={id}>{byId.get(String(id))?.title ?? `Livre ${String(id).slice(0,8)}`}</span>)}</div></td><td>{new Date(order.created_at).toLocaleString('fr-FR')}</td><td className="price-cell">{money(order.total_price)}</td><td><div className="order-status-cell"><Status status={order.status}/><select className="compact-select status-select" aria-label={`Modifier le statut de la commande ${order.id.slice(0,8)}`} disabled={busyOrder === order.id} value={order.status} onChange={e => void changeStatus(order, e.target.value)}>{!statuses.some(item => item.value === order.status) && <option value={order.status}>{orderStatusLabel(order.status)}</option>}{statuses.map(({ value, label }) => <option key={value} value={value}>{label}</option>)}</select></div></td></tr>
  })}</tbody></table></div> : <Empty icon={ShoppingBag} title={orders.length ? 'Aucune commande trouvée' : 'Aucune commande'} text={orders.length ? 'Essayez une autre recherche ou un autre statut.' : 'Les commandes enregistrées apparaîtront ici.'}/>}</section>
}

function UsersPage({ customers, onEdit }: { customers: Customer[]; onEdit: (customer: Customer) => void }) {
  const [query, setQuery] = useState('')
  const filtered = customers.filter(customer => [customer.full_name, customer.email, customer.phone].some(value => value?.toLowerCase().includes(query.trim().toLowerCase())))
  return <section className="panel table-panel"><div className="table-tools"><div><h2>Comptes clients</h2><p className="muted">Les comptes sont créés depuis l’application. Le nom et le téléphone peuvent être corrigés ici.</p></div><span className="result-count">{filtered.length} / {customers.length} utilisateurs</span></div><div className="table-tools user-tools"><div className="search-box"><Search size={17}/><input aria-label="Rechercher un utilisateur" value={query} onChange={e => setQuery(e.target.value)} placeholder="Nom, e-mail ou téléphone…" /></div></div>{filtered.length ? <div className="table-scroll"><table><thead><tr><th>CLIENT</th><th>TÉLÉPHONE</th><th>COMMANDES</th><th>INSCRIPTION</th><th>DERNIÈRE CONNEXION</th><th /></tr></thead><tbody>{filtered.map(customer => <tr key={customer.user_id}><td><div className="customer-cell"><div className="avatar customer-avatar">{(customer.full_name || customer.email || '?').slice(0, 1).toUpperCase()}</div><div><b>{customer.full_name || 'Nom non renseigné'}</b><small>{customer.email || 'E-mail indisponible'}</small></div></div></td><td>{customer.phone || <span className="muted">—</span>}</td><td>{customer.order_count}</td><td>{new Date(customer.created_at).toLocaleDateString('fr-FR')}</td><td>{customer.last_sign_in_at ? new Date(customer.last_sign_in_at).toLocaleDateString('fr-FR') : 'Jamais'}</td><td><button className="button secondary compact-button" onClick={() => onEdit(customer)}>Modifier</button></td></tr>)}</tbody></table></div> : <Empty icon={Users} title={customers.length ? 'Aucun utilisateur trouvé' : 'Aucun utilisateur'} text={customers.length ? 'Essayez un autre nom, e-mail ou numéro.' : 'Les comptes clients créés apparaîtront ici.'}/>}</section>
}

function SchemaExplorer({ schema }: { schema: DbSchema | null }) {
  if (!schema) return <div className="panel"><Empty icon={CircleAlert} title="Schéma non chargé" text="Appliquez la migration admin, puis actualisez la page."/></div>
  const fkCount = schema.tables.reduce((sum, table) => sum + table.foreign_keys.length, 0)
  return <>
    <div className="schema-summary"><div className="stat-card"><div className="stat-top">Tables détectées <i><LayoutDashboard size={18}/></i></div><strong>{schema.tables.length}</strong><small>Schéma public Supabase</small></div><div className="stat-card"><div className="stat-top">Clés étrangères <i><ArrowUpRight size={18}/></i></div><strong>{fkCount}</strong><small>Relations déclarées dans PostgreSQL</small></div><div className="stat-card"><div className="stat-top">Relation spéciale <i><PackageCheck size={18}/></i></div><strong>JSON</strong><small>orders.book_ids → books.id</small></div></div>
    <div className="schema-grid">{schema.tables.map(table => <section className="panel schema-table" key={table.name}><div className="panel-heading"><div><h2>{table.name}</h2><p>{table.columns.length} colonnes · public.{table.name}</p></div><span className="format-pill format-ready">TABLE</span></div><div className="schema-columns">{table.columns.map(column => <div className="schema-column" key={column.name}><div><b>{column.name}</b>{column.primary_key && <span className="key-badge">PK</span>}{column.nullable && <span className="null-badge">NULL</span>}</div><code>{column.type}{column.udt_name !== column.type ? ` · ${column.udt_name}` : ''}</code>{column.default && <small>défaut : {column.default}</small>}{table.foreign_keys.filter(fk => fk.column === column.name).map(fk => <small className="relation-hint" key={fk.constraint}>→ {fk.referenced_schema}.{fk.referenced_table}.{fk.referenced_column}</small>)}</div>)}</div>{table.foreign_keys.length > 0 && <div className="relations-box"><b>Relations déclarées</b>{table.foreign_keys.map(fk => <div key={fk.constraint}><ArrowUpRight size={14}/><code>{fk.column}</code> vers <code>{fk.referenced_schema}.{fk.referenced_table}.{fk.referenced_column}</code></div>)}</div>}</section>)}</div>
    <section className="panel json-relation"><div className="row-icon"><FileText size={18}/></div><div><b>Relation des livres dans les commandes</b><p>`orders.book_ids` contient des IDs de livres dans un tableau JSON. Ce n’est pas une clé étrangère : la console résout ces IDs contre `books.id` pour afficher les titres. Les quantités par livre ne sont pas stockées dans cette relation actuelle.</p></div></section>
  </>
}

function CustomerEditor({ customer, close, saved, flash }: { customer: Customer; close: () => void; saved: (customer: Customer) => void; flash: (text: string, bad?: boolean) => void }) {
  const [fullName, setFullName] = useState(customer.full_name ?? '')
  const [phone, setPhone] = useState(customer.phone ?? '')
  const [busy, setBusy] = useState(false)
  async function submit(event: FormEvent) {
    event.preventDefault()
    if (!supabase) return
    setBusy(true)
    const { error } = await supabase.rpc('admin_update_user_profile', {
      p_user_id: customer.user_id,
      p_full_name: fullName.trim(),
      p_phone: phone.trim(),
    })
    setBusy(false)
    if (error) { flash(error.message, true); return }
    saved({ ...customer, full_name: fullName.trim() || null, phone: phone.trim() || null })
  }
  return <div className="modal-backdrop" onMouseDown={event => { if (event.target === event.currentTarget) close() }}><section className="editor-modal"><div className="modal-heading"><div><div className="eyebrow">COMPTE CLIENT</div><h2>Modifier les coordonnées</h2><p>{customer.email || 'E-mail indisponible'}</p></div><button className="icon-button" onClick={close} aria-label="Fermer"><X/></button></div><form onSubmit={submit} className="editor-form"><label>Nom complet<input autoComplete="name" value={fullName} onChange={event => setFullName(event.target.value)} placeholder="Nom du client" /></label><label>Téléphone<input autoComplete="tel" type="tel" value={phone} onChange={event => setPhone(event.target.value)} placeholder="Numéro de téléphone" /></label><p className="form-note">L’adresse e-mail et l’identifiant du compte sont gérés par Supabase Auth.</p><div className="modal-actions"><button type="button" className="button secondary" onClick={close}>Annuler</button><button className="button primary" disabled={busy}>{busy ? 'Enregistrement…' : 'Enregistrer'}</button></div></form></section></div>
}

function BookEditor({ book, schema, close, saved, flash }: { book: Book | null; schema: DbSchema | null; close: () => void; saved: (book: Book) => void; flash: (text: string, bad?: boolean) => void }) {
  const booksTable = useMemo(() => schema?.tables.find(item => item.name === 'books'), [schema])
  const columns = booksTable?.columns ?? []
  const foreignKeys = booksTable?.foreign_keys ?? emptyForeignKeys
  const primaryKey = columns.find(column => column.primary_key)?.name ?? 'id'
  const [draft, setDraft] = useState<Record<string, unknown>>(() => book ? { ...book } : Object.fromEntries(columns.map(column => [column.name, ''])))
  const [busy, setBusy] = useState(false)
  const [references, setReferences] = useState<Record<string, { value: string; label: string }[]>>({})
  const table = useMemo(() => columns, [columns])
  useEffect(() => {
    if (!supabase) return
    let active = true
    Promise.all(foreignKeys.filter(fk => fk.referenced_schema === 'public').map(async fk => {
      const { data } = await supabase.from(fk.referenced_table).select('*').limit(200)
      if (!data) return null
      const options = data.map((row: Record<string, unknown>) => {
        const value = String(row[fk.referenced_column] ?? '')
        const label = String(row.title ?? row.name ?? row.label ?? value)
        return { value, label }
      })
      return [fk.column, options] as const
    })).then(entries => { if (active) setReferences(Object.fromEntries(entries.filter((entry): entry is readonly [string, { value: string; label: string }[]] => entry !== null))) })
    return () => { active = false }
  }, [foreignKeys])
  function valueOf(column: DbColumn) { const value = draft[column.name]; return value == null ? '' : typeof value === 'object' ? JSON.stringify(value) : String(value) }
  function update(column: DbColumn, value: unknown) { setDraft(current => ({ ...current, [column.name]: value })) }
  async function submit(event: FormEvent) {
    event.preventDefault(); if (!supabase) return; setBusy(true)
    const editable = table.filter(column => !isAutomaticColumn(column) && column.name !== 'reading_path')
    const payload: Record<string, unknown> = {}
    for (const column of editable) {
      const raw = draft[column.name]
      if (raw === '' || raw === undefined) { if (column.nullable) payload[column.name] = null; continue }
      if (column.type === 'json' || column.type === 'jsonb') {
        try { payload[column.name] = typeof raw === 'string' ? JSON.parse(raw) : raw } catch { flash(`Valeur JSON invalide : ${column.name}`, true); setBusy(false); return }
      } else payload[column.name] = raw
    }
    const { data: { session } } = await supabase.auth.getSession()
    const now = new Date().toISOString()
    for (const column of table) {
      if (!isAutomaticColumn(column)) continue
      const name = column.name.toLowerCase()
      if (column.generated || column.identity) continue
      if (name === 'updated_at' || name === 'updated_on') { payload[column.name] = now; continue }
      if (name === 'updated_by') { if (session?.user.id) payload[column.name] = session.user.id; continue }
      if (column.default) continue
      if (name === 'id' && column.type.toLowerCase() === 'uuid' && !book) {
        payload[column.name] = crypto.randomUUID()
      } else if (['user_id', 'owner_id', 'created_by'].includes(name)) {
        const existing = book ? (book as unknown as Record<string, unknown>)[column.name] : null
        if (existing != null) payload[column.name] = existing
        else if (session?.user.id) payload[column.name] = session.user.id
      } else if (!book && ['created_at', 'created_on'].includes(name)) {
        payload[column.name] = now
      }
    }
    const primaryValue = book ? (book as unknown as Record<string, unknown>)[primaryKey] : null
    const result = book
      ? await supabase.from('books').update(payload).eq(primaryKey, primaryValue).select().single()
      : await supabase.from('books').insert(payload).select().single()
    setBusy(false)
    if (result.error) { flash(result.error.message, true); return }
    saved(result.data as Book)
  }
  const labelFor = (column: DbColumn) => column.name.replaceAll('_', ' ').replace(/\b\w/g, letter => letter.toUpperCase())
  const editableColumns = table.filter(column => !isAutomaticColumn(column))
  return <div className="modal-backdrop" onMouseDown={e => { if (e.target === e.currentTarget) close() }}><section className="editor-modal"><div className="modal-heading"><div><div className="eyebrow">PUBLIC.BOOKS · {table.length} COLONNES</div><h2>{book ? 'Modifier le livre' : 'Ajouter un livre'}</h2><p>Les champs système et les valeurs par défaut sont remplis automatiquement.</p></div><button className="icon-button" onClick={close}><X/></button></div>{!columns.length ? <div className="schema-warning"><CircleAlert/>Le schéma n’a pas été chargé. Appliquez la migration admin pour afficher les vrais champs.</div> : <form onSubmit={submit} className="editor-form">{editableColumns.map(column => {
    const fk = foreignKeys.find(item => item.column === column.name)
    const required = !column.nullable && !column.default && !column.identity && !column.generated
    const type = column.type.toLowerCase()
    const current = valueOf(column)
    return <label key={column.name}>{labelFor(column)} <span className="column-meta">{column.name} · {column.type}{column.nullable ? ' · nullable' : ' · requis'}</span>
      {column.name === 'reading_path' ? <input value={current || 'Géré dans Fichiers de lecture'} readOnly title="Associez le fichier depuis Fichiers de lecture"/> : fk && references[column.name] ? <select required={required} value={current} onChange={e => update(column, e.target.value)}><option value="">Choisir {labelFor(column).toLowerCase()}…</option>{references[column.name].map(option => <option key={option.value} value={option.value}>{option.label}</option>)}</select> : type === 'boolean' ? <input type="checkbox" checked={Boolean(draft[column.name])} onChange={e => update(column, e.target.checked)}/> : (type === 'json' || type === 'jsonb') ? <textarea rows={4} required={required} value={current} onChange={e => update(column, e.target.value)} placeholder="Valeur JSON"/> : type.includes('int') || type.includes('numeric') || type.includes('decimal') || type === 'real' || type === 'double precision' ? <input type="number" step="any" required={required} value={current} onChange={e => update(column, e.target.value === '' ? '' : Number(e.target.value))}/> : type === 'text' && (column.name.includes('description') || column.name.includes('content')) ? <textarea rows={5} required={required} value={current} onChange={e => update(column, e.target.value)}/> : <input type={column.name.includes('url') ? 'url' : 'text'} required={required} value={current} onChange={e => update(column, e.target.value)} readOnly={Boolean(fk && fk.referenced_schema !== 'public')}/>}</label>
  })}<div className="modal-actions"><button type="button" className="button secondary" onClick={close}>Annuler</button><button className="button primary" disabled={busy}>{busy ? 'Enregistrement…' : 'Enregistrer le livre'}</button></div></form>}</section></div>
}

function isAutomaticColumn(column: DbColumn) {
  const name = column.name.toLowerCase()
  return column.generated || column.identity || Boolean(column.default) ||
    (column.primary_key && name === 'id') ||
    ['id', 'created_at', 'updated_at', 'created_on', 'updated_on', 'user_id', 'owner_id', 'created_by', 'updated_by'].includes(name)
}

function Cover({ book }: { book: Book }) { return book.cover_url ? <img className="book-cover" src={book.cover_url} alt="" loading="lazy"/> : <div className="book-cover cover-placeholder"><BookOpen size={17}/></div> }
function Status({ status }: { status: string }) { const pending = status === 'en_attente'; const cancelled = status === 'annulee'; return <span className={`status-pill ${pending ? 'status-pending' : cancelled ? 'status-cancelled' : 'status-done'}`}><i/> {orderStatusLabel(status)}</span> }
function Empty({ icon: Icon, title, text }: { icon: typeof Heart; title: string; text: string }) { return <div className="empty-state"><Icon size={25}/><b>{title}</b><p>{text}</p></div> }
