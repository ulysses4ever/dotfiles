/* midi-ports — the ALSA sequencer ports as RtMidi (PianoBooster) and midir
 * (Neothesia) list them: client by client, skipping the System client, only
 * MIDI, synth and application ports, inputs (readable) and then outputs
 * (writable). One line each, tab-separated: in|out, the port's position in
 * that list, its client's name, and the name those libraries give it,
 * "client:port client-number:port-number". See piano-apps.py. */
#include <alsa/asoundlib.h>
#include <stdio.h>

static void list(snd_seq_t *seq, const char *direction, unsigned int caps)
{
	snd_seq_client_info_t *cinfo;
	snd_seq_port_info_t *pinfo;
	int index = 0;

	snd_seq_client_info_alloca(&cinfo);
	snd_seq_port_info_alloca(&pinfo);
	snd_seq_client_info_set_client(cinfo, -1);
	while (snd_seq_query_next_client(seq, cinfo) >= 0) {
		int client = snd_seq_client_info_get_client(cinfo);
		const char *cname = snd_seq_client_info_get_name(cinfo);

		if (client == 0)
			continue;
		snd_seq_port_info_set_client(pinfo, client);
		snd_seq_port_info_set_port(pinfo, -1);
		while (snd_seq_query_next_port(seq, pinfo) >= 0) {
			unsigned int type = snd_seq_port_info_get_type(pinfo);

			if (!(type & (SND_SEQ_PORT_TYPE_MIDI_GENERIC | SND_SEQ_PORT_TYPE_SYNTH |
				      SND_SEQ_PORT_TYPE_APPLICATION)))
				continue;
			if ((snd_seq_port_info_get_capability(pinfo) & caps) != caps)
				continue;
			printf("%s\t%d\t%s\t%s:%s %d:%d\n", direction, index++, cname, cname,
			       snd_seq_port_info_get_name(pinfo), client,
			       snd_seq_port_info_get_port(pinfo));
		}
	}
}

int main(void)
{
	snd_seq_t *seq;

	if (snd_seq_open(&seq, "default", SND_SEQ_OPEN_DUPLEX, 0) < 0)
		return 1;
	list(seq, "in", SND_SEQ_PORT_CAP_READ | SND_SEQ_PORT_CAP_SUBS_READ);
	list(seq, "out", SND_SEQ_PORT_CAP_WRITE | SND_SEQ_PORT_CAP_SUBS_WRITE);
	return 0;
}
