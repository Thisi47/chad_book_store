import { useCallback, useEffect, useMemo, useState, type FormEvent } from 'react'
import {
  Activity, ArrowDownToLine, ArrowUpRight, BookOpen, Check, ChevronDown,
  CircleAlert, CloudUpload, FileText, Heart, LayoutDashboard, Library,
  LogOut, Menu, PackageCheck, Plus, Search, Settings2, ShoppingBag,
  Trash2, X,
} from 'lucide-react'
import { isSupabaseConfigured, supabase, type Book, type Order } from './supabase'
import './App.css'

type Section = 'overview' | 'books' | 'documents' | 'orders'
type BookDraft = Omit<Book, 'id'>
const emptyDraft: BookDraft = {
  title: '', author: '', price: 0, category: '', description: '', cover_url: '', reading_path: null,
}
const formatName = (path: string | null) => path?.split('.').pop()?.toUpperCase() ?? 'MANQUANT'
const money = (amount: number) => new Intl.NumberFormat('fr-FR').format(amount) + ' FCFA'

export default function App() {
  const [session, setSession] = useState<Awaited<ReturnType<NonNullable<typeof supabase>['auth']['getSession']>>['data']['session']>(null)
  const [admin, setAdmin] = useState(false)
  const [checking, setChecking] = useState(true)
  const [section, setSection] = useState<Section>('overview')
  const [books, setBooks] = useState<Book[]>([])
  const [orders, setOrders] = useState<Order[]>([])
  const [search, setSearch] = useState('')
  const [notice, setNotice] = useState<{ text: string; bad?: boolean } | null>(null)
  const [loading, setLoading] = useState(false)
  const [editing, setEditing] = useState<Book | null | false>(false)
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
    const [bookResult, orderResult] = await Promise.all([
      supabase.from('books').select('*').order('title'),
      supabase.from('orders').select('id,user_id,total_price,status,created_at').order('created_at', { ascending: false }).limit(100),
    ])
    if (bookResult.error) flash(bookResult.error.message, true)
    else setBooks((bookResult.data ?? []) as Book[])
    if (orderResult.error) flash(orderResult.error.message, true)
    else setOrders((orderResult.data ?? []) as Order[])
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
      if (!next) { setAdmin(false); setBooks([]); setOrders([]) }
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
  ]
  const titles: Record<Section, [string, string]> = {
    overview: ['Bonjour, administrateur', 'Voici l’activité de votre librairie.'],
    books: ['Catalogue', 'Gérez les livres proposés dans l’application.'],
    documents: ['Fichiers de lecture', 'Reliez les documents aux livres de votre catalogue.'],
    orders: ['Commandes', 'Consultez les commandes enregistrées.'],
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
        {section === 'orders' && <Orders orders={orders} />}
      </div>
    </main>
    {editing !== false && <BookEditor book={editing || null} close={() => setEditing(false)} saved={book => { setBooks(current => { const found = current.some(item => item.id === book.id); return found ? current.map(item => item.id === book.id ? book : item) : [...current, book].sort((a,b) => a.title.localeCompare(b.title)) }); setEditing(false); flash('Le livre a été enregistré.') }} flash={flash} />}
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
    <div className="stat-grid"><Stat icon={Library} label="Livres au catalogue" value={books.length.toString()} hint="Livres disponibles"/><Stat icon={FileText} label="Fichiers à relier" value={missingFiles.toString()} hint={missingFiles ? 'Lecture à configurer' : 'Tout est prêt'} warn={missingFiles > 0}/><Stat icon={PackageCheck} label="Commandes en attente" value={pendingOrders.toString()} hint="Suivi uniquement"/><Stat icon={Activity} label="Commandes enregistrées" value={orders.length.toString()} hint={`Total cumulé : ${money(total)}`}/></div>
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

function Orders({ orders }: { orders: Order[] }) { return <section className="panel table-panel"><div className="table-tools"><div><h2>Commandes récentes</h2><p className="muted">Consultation uniquement — le processus d’achat n’est pas géré ici.</p></div><span className="result-count">{orders.length} commandes</span></div>{orders.length ? <div className="table-scroll"><table><thead><tr><th>RÉFÉRENCE</th><th>CLIENT</th><th>DATE</th><th>MONTANT</th><th>STATUT</th></tr></thead><tbody>{orders.map(order => <tr key={order.id}><td><b>#{order.id.slice(0,8)}</b></td><td><code>{order.user_id.slice(0,8)}…</code></td><td>{new Date(order.created_at).toLocaleString('fr-FR')}</td><td className="price-cell">{money(order.total_price)}</td><td><Status status={order.status}/></td></tr>)}</tbody></table></div> : <Empty icon={ShoppingBag} title="Aucune commande" text="Les commandes enregistrées apparaîtront ici."/>}</section> }

function BookEditor({ book, close, saved, flash }: { book: Book | null; close: () => void; saved: (book: Book) => void; flash: (text: string, bad?: boolean) => void }) {
  const [draft, setDraft] = useState<BookDraft>(book ? { title: book.title, author: book.author, price: book.price, category: book.category ?? '', description: book.description ?? '', cover_url: book.cover_url ?? '', reading_path: book.reading_path } : emptyDraft)
  const [busy, setBusy] = useState(false)
  const set = (key: keyof BookDraft, value: string | number | null) => setDraft(prev => ({ ...prev, [key]: value }))
  async function submit(event: FormEvent) {
    event.preventDefault(); if (!supabase) return; setBusy(true)
    const payload = { ...draft, category: draft.category || null, description: draft.description || null, cover_url: draft.cover_url || null }
    const result = book
      ? await supabase.from('books').update(payload).eq('id', book.id).select().single()
      : await supabase.from('books').insert(payload).select().single()
    setBusy(false)
    if (result.error) { flash(result.error.message, true); return }
    saved(result.data as Book)
  }
  return <div className="modal-backdrop" onMouseDown={e => { if (e.target === e.currentTarget) close() }}><section className="editor-modal"><div className="modal-heading"><div><div className="eyebrow">CATALOGUE</div><h2>{book ? 'Modifier le livre' : 'Ajouter un livre'}</h2></div><button className="icon-button" onClick={close}><X/></button></div><form onSubmit={submit} className="editor-form"><label>Titre<input required value={draft.title} onChange={e => set('title',e.target.value)} placeholder="Titre du livre"/></label><div className="form-row"><label>Auteur<input required value={draft.author} onChange={e => set('author',e.target.value)} placeholder="Nom de l’auteur"/></label><label>Prix (FCFA)<input required min="0" type="number" value={draft.price} onChange={e => set('price',Number(e.target.value))}/></label></div><label>Catégorie<input value={draft.category ?? ''} onChange={e => set('category',e.target.value)} placeholder="Roman, histoire…"/></label><label>URL de couverture<input type="url" value={draft.cover_url ?? ''} onChange={e => set('cover_url',e.target.value)} placeholder="https://…"/></label><label>Description<textarea rows={5} value={draft.description ?? ''} onChange={e => set('description',e.target.value)} placeholder="Présentez le livre aux lecteurs…"/></label><div className="modal-actions"><button type="button" className="button secondary" onClick={close}>Annuler</button><button className="button primary" disabled={busy}>{busy ? 'Enregistrement…' : 'Enregistrer le livre'}</button></div></form></section></div>
}

function Cover({ book }: { book: Book }) { return book.cover_url ? <img className="book-cover" src={book.cover_url} alt="" loading="lazy"/> : <div className="book-cover cover-placeholder"><BookOpen size={17}/></div> }
function Status({ status }: { status: string }) { const pending = status === 'en_attente'; return <span className={`status-pill ${pending ? 'status-pending' : 'status-done'}`}><i/> {pending ? 'En attente' : status}</span> }
function Empty({ icon: Icon, title, text }: { icon: typeof Heart; title: string; text: string }) { return <div className="empty-state"><Icon size={25}/><b>{title}</b><p>{text}</p></div> }
