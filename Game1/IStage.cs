using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using TankyReloaded.Actors;

namespace TankyReloaded
{
    public interface IStage
    {
        ICollection<IStageObject> Objects { get; }
        void Draw(SpriteBatch spriteBatch);
        void Add(IStageObject stageObject);
        void AddRelative(IStageObject subject, IStageObject origin, RelativePosition relativePosition);
        void Update(GameTime gameTime);
    }
}